-- ================================================
-- Mots Mawon - Schema de Base de Données
-- ================================================
-- Ce fichier doit être exécuté dans le SQL Editor de Supabase
-- Il crée la table, les policies RLS, et les fonctions nécessaires

-- ================================================
-- 1. TABLE PRINCIPALE
-- ================================================

CREATE TABLE IF NOT EXISTS mots_mawon_games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  status TEXT NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'completed', 'abandoned')),

  grid_data JSONB NOT NULL,
  -- Structure JSON: {"grid": [[...]], "size": 12, "words": [...]}

  found_words TEXT[] NOT NULL DEFAULT '{}',
  score INTEGER NOT NULL DEFAULT 0,
  time_elapsed INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- ================================================
-- 2. INDEXES POUR PERFORMANCE
-- ================================================

CREATE INDEX IF NOT EXISTS idx_mots_mawon_games_user_id
  ON mots_mawon_games(user_id);

CREATE INDEX IF NOT EXISTS idx_mots_mawon_games_status
  ON mots_mawon_games(status);

CREATE INDEX IF NOT EXISTS idx_mots_mawon_games_score
  ON mots_mawon_games(score DESC)
  WHERE status = 'completed';

-- Index unique partiel: un seul jeu en cours par utilisateur
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_game_per_user
  ON mots_mawon_games(user_id)
  WHERE status = 'in_progress';

-- ================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- ================================================

ALTER TABLE mots_mawon_games ENABLE ROW LEVEL SECURITY;

-- L'utilisateur voit ses propres parties
DROP POLICY IF EXISTS "Users can view their own games" ON mots_mawon_games;
CREATE POLICY "Users can view their own games"
  ON mots_mawon_games FOR SELECT
  USING (auth.uid() = user_id);

-- L'utilisateur crée ses propres parties
DROP POLICY IF EXISTS "Users can create their own games" ON mots_mawon_games;
CREATE POLICY "Users can create their own games"
  ON mots_mawon_games FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- L'utilisateur modifie uniquement ses parties en cours
DROP POLICY IF EXISTS "Users can update their own in_progress games" ON mots_mawon_games;
CREATE POLICY "Users can update their own in_progress games"
  ON mots_mawon_games FOR UPDATE
  USING (auth.uid() = user_id AND status = 'in_progress')
  WITH CHECK (auth.uid() = user_id);

-- Lecture publique des parties complétées pour leaderboard
DROP POLICY IF EXISTS "Public can view completed games for leaderboard" ON mots_mawon_games;
CREATE POLICY "Public can view completed games for leaderboard"
  ON mots_mawon_games FOR SELECT
  USING (status = 'completed');

-- ================================================
-- 4. TRIGGER POUR updated_at
-- ================================================

-- Fonction pour mettre à jour updated_at (si elle n'existe pas déjà)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger sur mots_mawon_games
DROP TRIGGER IF EXISTS update_mots_mawon_games_updated_at ON mots_mawon_games;
CREATE TRIGGER update_mots_mawon_games_updated_at
  BEFORE UPDATE ON mots_mawon_games
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 5. FONCTION LEADERBOARD
-- ================================================

CREATE OR REPLACE FUNCTION get_mots_mawon_leaderboard(
  limit_count INTEGER DEFAULT 50,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
  game_id UUID,
  user_id UUID,
  username TEXT,
  score INTEGER,
  time_elapsed INTEGER,
  completed_at TIMESTAMPTZ,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    mmg.id as game_id,
    mmg.user_id,
    u.username,
    mmg.score,
    mmg.time_elapsed,
    mmg.completed_at,
    ROW_NUMBER() OVER (ORDER BY mmg.score DESC, mmg.time_elapsed ASC) as rank
  FROM mots_mawon_games mmg
  JOIN users u ON u.id = mmg.user_id
  WHERE mmg.status = 'completed'
  ORDER BY mmg.score DESC, mmg.time_elapsed ASC
  LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- 6. FONCTION STATISTIQUES JOUEUR
-- ================================================

CREATE OR REPLACE FUNCTION get_mots_mawon_player_stats(player_id UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_games', COUNT(*),
    'completed_games', COUNT(*) FILTER (WHERE status = 'completed'),
    'in_progress_games', COUNT(*) FILTER (WHERE status = 'in_progress'),
    'abandoned_games', COUNT(*) FILTER (WHERE status = 'abandoned'),
    'total_score', COALESCE(SUM(score) FILTER (WHERE status = 'completed'), 0),
    'average_score', COALESCE(ROUND(AVG(score) FILTER (WHERE status = 'completed'), 2), 0),
    'best_score', COALESCE(MAX(score) FILTER (WHERE status = 'completed'), 0),
    'total_time', COALESCE(SUM(time_elapsed) FILTER (WHERE status = 'completed'), 0),
    'average_time', COALESCE(ROUND(AVG(time_elapsed) FILTER (WHERE status = 'completed'), 2), 0),
    'best_time', COALESCE(MIN(time_elapsed) FILTER (WHERE status = 'completed' AND time_elapsed > 0), 0),
    'total_words_found', COALESCE(SUM(array_length(found_words, 1)), 0)
  ) INTO stats
  FROM mots_mawon_games
  WHERE user_id = player_id;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- FIN DU SCRIPT
-- ================================================

-- Vérification : Afficher les tables créées
SELECT 'Tables créées:' as info;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = 'mots_mawon_games';

SELECT 'Indexes créés:' as info;
SELECT indexname FROM pg_indexes WHERE tablename = 'mots_mawon_games';

SELECT 'Policies créées:' as info;
SELECT policyname FROM pg_policies WHERE tablename = 'mots_mawon_games';

SELECT 'Fonctions créées:' as info;
SELECT routine_name FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_mots_mawon_leaderboard', 'get_mots_mawon_player_stats');
