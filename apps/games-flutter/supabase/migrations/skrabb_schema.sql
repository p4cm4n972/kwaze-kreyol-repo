-- ================================================
-- Skrabb (Scrabble Créole) - Database Schema
-- ================================================

-- Table des parties Skrabb
CREATE TABLE IF NOT EXISTS skrabb_games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  status TEXT NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'completed', 'abandoned')),

  -- État du jeu stocké en JSONB
  board_data JSONB NOT NULL,
  -- Structure: {"size": 15, "squares": [[{row, col, bonusType, placedTile, isLocked}]]}

  rack JSONB NOT NULL DEFAULT '[]',
  -- Structure: [{"letter": "A", "value": 1, "isBlank": false}, ...]

  tile_bag JSONB NOT NULL,
  -- Structure: même que rack

  move_history JSONB NOT NULL DEFAULT '[]',
  -- Structure: [{"placedTiles": [...], "formedWords": [...], "score": 10, "isBingo": false, "timestamp": "..."}, ...]

  score INTEGER NOT NULL DEFAULT 0,
  time_elapsed INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

-- ================================================
-- INDEXES
-- ================================================

CREATE INDEX IF NOT EXISTS idx_skrabb_games_user_id
  ON skrabb_games(user_id);

CREATE INDEX IF NOT EXISTS idx_skrabb_games_status
  ON skrabb_games(status);

CREATE INDEX IF NOT EXISTS idx_skrabb_games_score
  ON skrabb_games(score DESC)
  WHERE status = 'completed';

CREATE INDEX IF NOT EXISTS idx_skrabb_games_created_at
  ON skrabb_games(created_at DESC);

-- Index unique: un seul jeu actif par utilisateur
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_skrabb_game
  ON skrabb_games(user_id)
  WHERE status = 'in_progress';

-- ================================================
-- ROW LEVEL SECURITY
-- ================================================

ALTER TABLE skrabb_games ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir leurs propres parties
CREATE POLICY "Users can view their own games"
  ON skrabb_games FOR SELECT
  USING (auth.uid() = user_id);

-- Les utilisateurs peuvent créer leurs propres parties
CREATE POLICY "Users can create their own games"
  ON skrabb_games FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent mettre à jour leurs parties en cours
CREATE POLICY "Users can update their own in_progress games"
  ON skrabb_games FOR UPDATE
  USING (auth.uid() = user_id AND status = 'in_progress')
  WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent supprimer leurs propres parties
CREATE POLICY "Users can delete their own games"
  ON skrabb_games FOR DELETE
  USING (auth.uid() = user_id);

-- Accès public au classement (parties complétées)
CREATE POLICY "Public can view completed games for leaderboard"
  ON skrabb_games FOR SELECT
  USING (status = 'completed');

-- ================================================
-- TRIGGER FOR updated_at
-- ================================================

-- Fonction pour mettre à jour updated_at (si elle n'existe pas déjà)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_skrabb_games_updated_at
  BEFORE UPDATE ON skrabb_games
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- LEADERBOARD FUNCTION
-- ================================================

CREATE OR REPLACE FUNCTION get_skrabb_leaderboard(
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
    sg.id as game_id,
    sg.user_id,
    u.username,
    sg.score,
    sg.time_elapsed,
    sg.completed_at,
    ROW_NUMBER() OVER (ORDER BY sg.score DESC, sg.time_elapsed ASC) as rank
  FROM skrabb_games sg
  JOIN users u ON u.id = sg.user_id
  WHERE sg.status = 'completed'
  ORDER BY sg.score DESC, sg.time_elapsed ASC
  LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- PLAYER STATISTICS FUNCTION
-- ================================================

CREATE OR REPLACE FUNCTION get_skrabb_player_stats(player_id UUID)
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
    'best_time', COALESCE(MIN(time_elapsed) FILTER (WHERE status = 'completed' AND time_elapsed > 0), 0)
  ) INTO stats
  FROM skrabb_games
  WHERE user_id = player_id;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- COMMENTS
-- ================================================

COMMENT ON TABLE skrabb_games IS 'Parties de Skrabb (Scrabble créole)';
COMMENT ON COLUMN skrabb_games.board_data IS 'État complet du plateau 15x15 avec tuiles et bonus';
COMMENT ON COLUMN skrabb_games.rack IS 'Chevalet du joueur (7 tuiles maximum)';
COMMENT ON COLUMN skrabb_games.tile_bag IS 'Sac de lettres restantes à piocher';
COMMENT ON COLUMN skrabb_games.move_history IS 'Historique de tous les coups joués';
COMMENT ON COLUMN skrabb_games.score IS 'Score total actuel';
COMMENT ON COLUMN skrabb_games.time_elapsed IS 'Temps écoulé en secondes';
