-- ================================================
-- SCRIPT DE CORRECTION DES FONCTIONS ADMIN
-- Exécutez ce script dans Supabase SQL Editor
-- ================================================

-- 1. SUPPRIMER toutes les fonctions existantes pour les recréer proprement
DROP FUNCTION IF EXISTS get_admin_user_stats();
DROP FUNCTION IF EXISTS get_admin_users_over_time(TEXT, INTEGER);
DROP FUNCTION IF EXISTS get_admin_active_users(INTEGER);
DROP FUNCTION IF EXISTS get_admin_domino_stats();
DROP FUNCTION IF EXISTS get_admin_skrabb_stats();
DROP FUNCTION IF EXISTS get_admin_mots_mawon_stats();
DROP FUNCTION IF EXISTS get_admin_domino_over_time(INTEGER);
DROP FUNCTION IF EXISTS get_admin_skrabb_over_time(INTEGER);
DROP FUNCTION IF EXISTS get_admin_mots_mawon_over_time(INTEGER);
DROP FUNCTION IF EXISTS get_admin_top_domino_players(INTEGER);
DROP FUNCTION IF EXISTS get_admin_top_skrabb_players(INTEGER);
DROP FUNCTION IF EXISTS get_admin_top_mots_mawon_players(INTEGER);

-- ================================================
-- 2. STATISTIQUES UTILISATEURS
-- ================================================

CREATE OR REPLACE FUNCTION get_admin_user_stats()
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  SELECT jsonb_build_object(
    'total_users', COUNT(*),
    'users_by_role', jsonb_build_object(
      'register', COUNT(*) FILTER (WHERE role = 'register'),
      'user', COUNT(*) FILTER (WHERE role = 'user'),
      'contributor', COUNT(*) FILTER (WHERE role = 'contributor'),
      'admin', COUNT(*) FILTER (WHERE role = 'admin')
    ),
    'new_users_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'new_users_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'new_users_this_month', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
  ) INTO stats
  FROM users;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get users over time (for graphs)
CREATE OR REPLACE FUNCTION get_admin_users_over_time(
  period TEXT DEFAULT 'daily',
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  date DATE,
  new_users BIGINT,
  cumulative_users BIGINT
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      CURRENT_DATE - (days_back || ' days')::INTERVAL,
      CURRENT_DATE,
      CASE period
        WHEN 'daily' THEN '1 day'::INTERVAL
        WHEN 'weekly' THEN '7 days'::INTERVAL
        WHEN 'monthly' THEN '1 month'::INTERVAL
        ELSE '1 day'::INTERVAL
      END
    )::DATE AS d
  ),
  daily_counts AS (
    SELECT
      created_at::DATE AS d,
      COUNT(*) AS cnt
    FROM users
    WHERE created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    GROUP BY created_at::DATE
  ),
  total_before AS (
    SELECT COUNT(*) AS cnt
    FROM users
    WHERE created_at < CURRENT_DATE - (days_back || ' days')::INTERVAL
  )
  SELECT
    ds.d AS date,
    COALESCE(dc.cnt, 0)::BIGINT AS new_users,
    ((SELECT cnt FROM total_before) + SUM(COALESCE(dc.cnt, 0)) OVER (ORDER BY ds.d))::BIGINT AS cumulative_users
  FROM date_series ds
  LEFT JOIN daily_counts dc ON ds.d = dc.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get active users (simplified - only domino for now)
CREATE OR REPLACE FUNCTION get_admin_active_users(days INTEGER DEFAULT 7)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
  domino_active BIGINT;
  total_active BIGINT;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Count unique active domino players
  SELECT COUNT(DISTINCT dp.user_id) INTO domino_active
  FROM domino_participants dp
  JOIN domino_sessions ds ON ds.id = dp.session_id
  WHERE ds.created_at >= CURRENT_DATE - (days || ' days')::INTERVAL
    AND dp.user_id IS NOT NULL;

  -- For now, total = domino (skrabb and mots_mawon tables might not exist)
  total_active := domino_active;

  SELECT jsonb_build_object(
    'period_days', days,
    'domino_active', domino_active,
    'skrabb_active', 0,
    'mots_mawon_active', 0,
    'total_active', total_active
  ) INTO stats;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 3. STATISTIQUES DOMINO
-- ================================================

CREATE OR REPLACE FUNCTION get_admin_domino_stats()
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  SELECT jsonb_build_object(
    'total_sessions', COUNT(*),
    'by_status', jsonb_build_object(
      'waiting', COUNT(*) FILTER (WHERE status = 'waiting'),
      'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
      'completed', COUNT(*) FILTER (WHERE status = 'completed'),
      'chiree', COUNT(*) FILTER (WHERE status = 'chiree'),
      'cancelled', COUNT(*) FILTER (WHERE status = 'cancelled')
    ),
    'avg_rounds_per_session', ROUND(COALESCE(AVG(total_rounds) FILTER (WHERE status IN ('completed', 'chiree')), 0)::NUMERIC, 1),
    'avg_duration_minutes', ROUND(COALESCE(
      AVG(EXTRACT(EPOCH FROM (completed_at - started_at)) / 60)
      FILTER (WHERE completed_at IS NOT NULL AND started_at IS NOT NULL), 0
    )::NUMERIC, 1),
    'sessions_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'sessions_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'sessions_this_month', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
  ) INTO stats
  FROM domino_sessions;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Games over time - Domino
CREATE OR REPLACE FUNCTION get_admin_domino_over_time(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  games_count BIGINT
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      CURRENT_DATE - (days_back || ' days')::INTERVAL,
      CURRENT_DATE,
      '1 day'::INTERVAL
    )::DATE AS d
  ),
  daily_counts AS (
    SELECT
      created_at::DATE AS d,
      COUNT(*) AS cnt
    FROM domino_sessions
    WHERE created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    GROUP BY created_at::DATE
  )
  SELECT
    ds.d AS date,
    COALESCE(dc.cnt, 0) AS games_count
  FROM date_series ds
  LEFT JOIN daily_counts dc ON ds.d = dc.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Top Domino players
CREATE OR REPLACE FUNCTION get_admin_top_domino_players(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  games_played BIGINT,
  total_wins BIGINT,
  win_rate NUMERIC
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  RETURN QUERY
  SELECT
    dp.user_id,
    u.username,
    COUNT(DISTINCT dp.session_id) AS games_played,
    COUNT(DISTINCT ds.id) FILTER (WHERE ds.winner_id = dp.user_id::TEXT) AS total_wins,
    ROUND(
      (COUNT(DISTINCT ds.id) FILTER (WHERE ds.winner_id = dp.user_id::TEXT)::NUMERIC /
       NULLIF(COUNT(DISTINCT dp.session_id), 0) * 100), 1
    ) AS win_rate
  FROM domino_participants dp
  JOIN users u ON u.id::TEXT = dp.user_id::TEXT
  JOIN domino_sessions ds ON ds.id = dp.session_id
  WHERE dp.user_id IS NOT NULL
    AND ds.status IN ('completed', 'chiree')
  GROUP BY dp.user_id, u.username
  ORDER BY total_wins DESC, win_rate DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 4. STATISTIQUES SKRABB (version sécurisée)
-- ================================================

CREATE OR REPLACE FUNCTION get_admin_skrabb_stats()
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
  table_exists BOOLEAN;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Check if table exists
  SELECT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'skrabb_games'
  ) INTO table_exists;

  IF NOT table_exists THEN
    RETURN jsonb_build_object(
      'total_games', 0,
      'by_status', jsonb_build_object('in_progress', 0, 'completed', 0, 'abandoned', 0),
      'avg_score', 0,
      'avg_time_seconds', 0,
      'highest_score', 0,
      'games_today', 0,
      'games_this_week', 0,
      'games_this_month', 0
    );
  END IF;

  SELECT jsonb_build_object(
    'total_games', COUNT(*),
    'by_status', jsonb_build_object(
      'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
      'completed', COUNT(*) FILTER (WHERE status = 'completed'),
      'abandoned', COUNT(*) FILTER (WHERE status = 'abandoned')
    ),
    'avg_score', ROUND(COALESCE(AVG(score) FILTER (WHERE status = 'completed'), 0)::NUMERIC, 1),
    'avg_time_seconds', ROUND(COALESCE(AVG(time_elapsed) FILTER (WHERE status = 'completed'), 0)::NUMERIC, 0),
    'highest_score', COALESCE(MAX(score) FILTER (WHERE status = 'completed'), 0),
    'games_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'games_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'games_this_month', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
  ) INTO stats
  FROM skrabb_games;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Games over time - Skrabb
CREATE OR REPLACE FUNCTION get_admin_skrabb_over_time(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  games_count BIGINT
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Return empty if table doesn't exist
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'skrabb_games'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      CURRENT_DATE - (days_back || ' days')::INTERVAL,
      CURRENT_DATE,
      '1 day'::INTERVAL
    )::DATE AS d
  ),
  daily_counts AS (
    SELECT
      created_at::DATE AS d,
      COUNT(*) AS cnt
    FROM skrabb_games
    WHERE created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    GROUP BY created_at::DATE
  )
  SELECT
    ds.d AS date,
    COALESCE(dc.cnt, 0) AS games_count
  FROM date_series ds
  LEFT JOIN daily_counts dc ON ds.d = dc.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Top Skrabb players
CREATE OR REPLACE FUNCTION get_admin_top_skrabb_players(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  games_played BIGINT,
  total_score BIGINT,
  avg_score NUMERIC
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Return empty if table doesn't exist
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'skrabb_games'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    sg.user_id,
    u.username,
    COUNT(*) AS games_played,
    SUM(sg.score)::BIGINT AS total_score,
    ROUND(AVG(sg.score)::NUMERIC, 1) AS avg_score
  FROM skrabb_games sg
  JOIN users u ON u.id::TEXT = sg.user_id::TEXT
  WHERE sg.status = 'completed'
  GROUP BY sg.user_id, u.username
  ORDER BY total_score DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 5. STATISTIQUES MOTS MAWON (version sécurisée)
-- ================================================

CREATE OR REPLACE FUNCTION get_admin_mots_mawon_stats()
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Check if table exists
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mots_mawon_games'
  ) THEN
    RETURN jsonb_build_object(
      'total_games', 0,
      'by_status', jsonb_build_object('in_progress', 0, 'completed', 0, 'abandoned', 0),
      'avg_score', 0,
      'avg_time_seconds', 0,
      'avg_words_found', 0,
      'games_today', 0,
      'games_this_week', 0,
      'games_this_month', 0
    );
  END IF;

  SELECT jsonb_build_object(
    'total_games', COUNT(*),
    'by_status', jsonb_build_object(
      'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress'),
      'completed', COUNT(*) FILTER (WHERE status = 'completed'),
      'abandoned', COUNT(*) FILTER (WHERE status = 'abandoned')
    ),
    'avg_score', ROUND(COALESCE(AVG(score) FILTER (WHERE status = 'completed'), 0)::NUMERIC, 1),
    'avg_time_seconds', ROUND(COALESCE(AVG(time_elapsed) FILTER (WHERE status = 'completed'), 0)::NUMERIC, 0),
    'avg_words_found', ROUND(COALESCE(AVG(array_length(found_words, 1)) FILTER (WHERE status = 'completed'), 0)::NUMERIC, 1),
    'games_today', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE),
    'games_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
    'games_this_month', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '30 days')
  ) INTO stats
  FROM mots_mawon_games;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Games over time - Mots Mawon
CREATE OR REPLACE FUNCTION get_admin_mots_mawon_over_time(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
  date DATE,
  games_count BIGINT
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Return empty if table doesn't exist
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mots_mawon_games'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH date_series AS (
    SELECT generate_series(
      CURRENT_DATE - (days_back || ' days')::INTERVAL,
      CURRENT_DATE,
      '1 day'::INTERVAL
    )::DATE AS d
  ),
  daily_counts AS (
    SELECT
      created_at::DATE AS d,
      COUNT(*) AS cnt
    FROM mots_mawon_games
    WHERE created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    GROUP BY created_at::DATE
  )
  SELECT
    ds.d AS date,
    COALESCE(dc.cnt, 0) AS games_count
  FROM date_series ds
  LEFT JOIN daily_counts dc ON ds.d = dc.d
  ORDER BY ds.d;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Top Mots Mawon players
CREATE OR REPLACE FUNCTION get_admin_top_mots_mawon_players(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  games_played BIGINT,
  total_score BIGINT,
  avg_score NUMERIC
) AS $$
BEGIN
  -- Check if caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM users
    WHERE id::TEXT = auth.uid()::TEXT AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Admin role required';
  END IF;

  -- Return empty if table doesn't exist
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mots_mawon_games'
  ) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    mmg.user_id,
    u.username,
    COUNT(*) AS games_played,
    SUM(mmg.score)::BIGINT AS total_score,
    ROUND(AVG(mmg.score)::NUMERIC, 1) AS avg_score
  FROM mots_mawon_games mmg
  JOIN users u ON u.id::TEXT = mmg.user_id::TEXT
  WHERE mmg.status = 'completed'
  GROUP BY mmg.user_id, u.username
  ORDER BY total_score DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- VERIFICATION
-- ================================================
SELECT 'Fonctions admin créées avec succès!' AS status;
