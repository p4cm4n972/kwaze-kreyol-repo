-- ============================================================================
-- DOMINOS MARTINIQUAIS - SCHEMA DATABASE
-- ============================================================================
-- Tables pour le jeu de dominos multijoueur (3 joueurs)
-- Règles: 7 tuiles par joueur, pas de pioche, capot ou bloqué
-- ============================================================================

-- ============================================================================
-- TABLE: domino_sessions
-- ============================================================================
CREATE TABLE domino_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  join_code TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'waiting'
    CHECK (status IN ('waiting', 'in_progress', 'completed', 'cancelled')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,

  winner_id UUID REFERENCES auth.users(id),
  winner_name TEXT,
  total_rounds INTEGER NOT NULL DEFAULT 0,

  -- État du jeu en temps réel (manche en cours)
  current_game_state JSONB,

  CONSTRAINT valid_winner CHECK (
    (winner_id IS NOT NULL AND winner_name IS NULL) OR
    (winner_id IS NULL AND winner_name IS NOT NULL) OR
    (winner_id IS NULL AND winner_name IS NULL)
  )
);

COMMENT ON TABLE domino_sessions IS 'Sessions de jeu de dominos (3 joueurs)';
COMMENT ON COLUMN domino_sessions.join_code IS 'Code à 6 chiffres pour rejoindre la partie';
COMMENT ON COLUMN domino_sessions.current_game_state IS 'État de la manche en cours (JSONB): plateau, mains, tour actuel';

-- ============================================================================
-- TABLE: domino_participants
-- ============================================================================
CREATE TABLE domino_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES domino_sessions(id) ON DELETE CASCADE,

  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  guest_name TEXT,

  turn_order INTEGER NOT NULL CHECK (turn_order IN (0, 1, 2)),
  rounds_won INTEGER NOT NULL DEFAULT 0,
  is_cochon BOOLEAN NOT NULL DEFAULT false,
  is_host BOOLEAN NOT NULL DEFAULT false,

  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT user_or_guest CHECK (
    (user_id IS NOT NULL AND guest_name IS NULL) OR
    (user_id IS NULL AND guest_name IS NOT NULL)
  ),

  CONSTRAINT unique_session_user UNIQUE (session_id, user_id),
  CONSTRAINT unique_turn_order UNIQUE (session_id, turn_order)
);

COMMENT ON TABLE domino_participants IS 'Participants dans une session de dominos';
COMMENT ON COLUMN domino_participants.turn_order IS 'Ordre de jeu: 0, 1 ou 2';
COMMENT ON COLUMN domino_participants.rounds_won IS 'Nombre de manches gagnées (max 3)';
COMMENT ON COLUMN domino_participants.is_cochon IS 'True si termine la partie avec 0 manche';

-- ============================================================================
-- TABLE: domino_rounds
-- ============================================================================
CREATE TABLE domino_rounds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES domino_sessions(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,

  winner_participant_id UUID REFERENCES domino_participants(id),
  end_type TEXT NOT NULL CHECK (end_type IN ('capot', 'blocked')),

  -- Scores finaux (points restants dans chaque main)
  final_scores JSONB NOT NULL,

  played_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT unique_session_round UNIQUE (session_id, round_number)
);

COMMENT ON TABLE domino_rounds IS 'Historique des manches terminées';
COMMENT ON COLUMN domino_rounds.end_type IS 'capot: joueur a posé toutes ses tuiles, blocked: jeu bloqué';
COMMENT ON COLUMN domino_rounds.final_scores IS 'Points restants par joueur: {participant_id: points}';

-- ============================================================================
-- TABLE: domino_invitations
-- ============================================================================
CREATE TABLE domino_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES domino_sessions(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'accepted', 'declined')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ,

  CONSTRAINT no_self_invite CHECK (inviter_id != invitee_id),
  CONSTRAINT unique_session_invitee UNIQUE (session_id, invitee_id)
);

COMMENT ON TABLE domino_invitations IS 'Invitations pour rejoindre une session';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- domino_sessions indexes
CREATE INDEX idx_domino_sessions_host ON domino_sessions(host_id);
CREATE INDEX idx_domino_sessions_status ON domino_sessions(status);
CREATE INDEX idx_domino_sessions_join_code ON domino_sessions(join_code) WHERE status = 'waiting';
CREATE INDEX idx_domino_sessions_completed ON domino_sessions(completed_at DESC) WHERE status = 'completed';

-- domino_participants indexes
CREATE INDEX idx_domino_participants_session ON domino_participants(session_id);
CREATE INDEX idx_domino_participants_user ON domino_participants(user_id);
CREATE INDEX idx_domino_participants_turn ON domino_participants(session_id, turn_order);

-- domino_rounds indexes
CREATE INDEX idx_domino_rounds_session ON domino_rounds(session_id, round_number);
CREATE INDEX idx_domino_rounds_played_at ON domino_rounds(played_at DESC);

-- domino_invitations indexes
CREATE INDEX idx_domino_invitations_invitee ON domino_invitations(invitee_id) WHERE status = 'pending';
CREATE INDEX idx_domino_invitations_session ON domino_invitations(session_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE domino_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE domino_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE domino_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE domino_invitations ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES: domino_sessions
-- ============================================================================

-- Lecture: participants + sessions publiques en attente (pour rejoindre)
CREATE POLICY "Users can view their own sessions"
  ON domino_sessions FOR SELECT
  USING (
    host_id = auth.uid() OR
    id IN (
      SELECT session_id FROM domino_participants
      WHERE user_id = auth.uid()
    ) OR
    (status = 'waiting' AND join_code IS NOT NULL)
  );

-- Création: utilisateurs authentifiés
CREATE POLICY "Authenticated users can create sessions"
  ON domino_sessions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = host_id);

-- Mise à jour: hôte uniquement
CREATE POLICY "Host can update their sessions"
  ON domino_sessions FOR UPDATE
  USING (host_id = auth.uid())
  WITH CHECK (host_id = auth.uid());

-- Suppression: hôte uniquement
CREATE POLICY "Host can delete their sessions"
  ON domino_sessions FOR DELETE
  USING (host_id = auth.uid());

-- ============================================================================
-- RLS POLICIES: domino_participants
-- ============================================================================

-- Lecture: participants de la session
CREATE POLICY "Users can view participants in their sessions"
  ON domino_participants FOR SELECT
  USING (
    session_id IN (
      SELECT id FROM domino_sessions
      WHERE host_id = auth.uid()
    ) OR
    session_id IN (
      SELECT session_id FROM domino_participants
      WHERE user_id = auth.uid()
    )
  );

-- Création: hôte ou via invitation
CREATE POLICY "Users can join sessions"
  ON domino_participants FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Hôte peut ajouter des participants
    session_id IN (
      SELECT id FROM domino_sessions
      WHERE host_id = auth.uid()
    ) OR
    -- Utilisateur peut se joindre lui-même
    user_id = auth.uid()
  );

-- Mise à jour: système uniquement (pour rounds_won, is_cochon)
CREATE POLICY "System can update participant stats"
  ON domino_participants FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Suppression: hôte uniquement
CREATE POLICY "Host can remove participants"
  ON domino_participants FOR DELETE
  USING (
    session_id IN (
      SELECT id FROM domino_sessions
      WHERE host_id = auth.uid()
    )
  );

-- ============================================================================
-- RLS POLICIES: domino_rounds
-- ============================================================================

-- Lecture: participants de la session
CREATE POLICY "Users can view rounds in their sessions"
  ON domino_rounds FOR SELECT
  USING (
    session_id IN (
      SELECT session_id FROM domino_participants
      WHERE user_id = auth.uid()
    )
  );

-- Création: système uniquement (via service)
CREATE POLICY "System can create rounds"
  ON domino_rounds FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================================
-- RLS POLICIES: domino_invitations
-- ============================================================================

-- Lecture: inviteur ou invité
CREATE POLICY "Users can view their invitations"
  ON domino_invitations FOR SELECT
  USING (
    inviter_id = auth.uid() OR
    invitee_id = auth.uid()
  );

-- Création: utilisateurs authentifiés
CREATE POLICY "Users can send invitations"
  ON domino_invitations FOR INSERT
  TO authenticated
  WITH CHECK (inviter_id = auth.uid());

-- Mise à jour: invité uniquement (pour répondre)
CREATE POLICY "Invitees can respond to invitations"
  ON domino_invitations FOR UPDATE
  USING (invitee_id = auth.uid())
  WITH CHECK (invitee_id = auth.uid());

-- Suppression: inviteur uniquement
CREATE POLICY "Inviters can delete invitations"
  ON domino_invitations FOR DELETE
  USING (inviter_id = auth.uid());

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger pour mettre à jour updated_at (si on ajoute cette colonne plus tard)
-- CREATE TRIGGER update_domino_sessions_updated_at
--   BEFORE UPDATE ON domino_sessions
--   FOR EACH ROW
--   EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RPC FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Génère un code unique à 6 chiffres pour rejoindre une session
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_domino_join_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    -- Génère un nombre aléatoire entre 100000 et 999999
    code := LPAD(FLOOR(RANDOM() * 900000 + 100000)::TEXT, 6, '0');

    -- Vérifie si le code existe déjà dans une session en attente
    SELECT EXISTS(
      SELECT 1 FROM domino_sessions
      WHERE join_code = code AND status = 'waiting'
    ) INTO code_exists;

    EXIT WHEN NOT code_exists;
  END LOOP;

  RETURN code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION generate_domino_join_code() IS 'Génère un code unique à 6 chiffres pour rejoindre une session';

-- ----------------------------------------------------------------------------
-- Incrémente le nombre de manches gagnées pour un participant
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_domino_rounds_won(participant_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE domino_participants
  SET rounds_won = rounds_won + 1
  WHERE id = participant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION increment_domino_rounds_won(UUID) IS 'Incrémente rounds_won pour un participant';

-- ----------------------------------------------------------------------------
-- Classement des joueurs de dominos
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_domino_leaderboard(
  limit_count INTEGER DEFAULT 50,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  total_sessions BIGINT,
  total_wins BIGINT,
  total_cochons BIGINT,
  win_rate NUMERIC,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT ds.id) AS total_sessions,
    COUNT(DISTINCT CASE WHEN ds.winner_id = u.id THEN ds.id END) AS total_wins,
    COUNT(CASE WHEN dp.is_cochon THEN 1 END) AS total_cochons,
    ROUND(
      COALESCE(
        COUNT(DISTINCT CASE WHEN ds.winner_id = u.id THEN ds.id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT ds.id), 0) * 100,
        0
      ),
      2
    ) AS win_rate,
    ROW_NUMBER() OVER (
      ORDER BY
        COUNT(DISTINCT CASE WHEN ds.winner_id = u.id THEN ds.id END) DESC,
        ROUND(
          COALESCE(
            COUNT(DISTINCT CASE WHEN ds.winner_id = u.id THEN ds.id END)::NUMERIC /
            NULLIF(COUNT(DISTINCT ds.id), 0) * 100,
            0
          ),
          2
        ) DESC,
        u.username ASC
    ) AS rank
  FROM users u
  LEFT JOIN domino_participants dp ON dp.user_id = u.id
  LEFT JOIN domino_sessions ds ON ds.id = dp.session_id AND ds.status = 'completed'
  GROUP BY u.id, u.username
  HAVING COUNT(DISTINCT ds.id) > 0
  ORDER BY rank
  LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_domino_leaderboard(INTEGER, INTEGER) IS 'Retourne le classement des joueurs de dominos';

-- ----------------------------------------------------------------------------
-- Statistiques d'un joueur
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_domino_player_stats(player_id UUID)
RETURNS JSONB AS $$
DECLARE
  stats JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_sessions', COUNT(DISTINCT ds.id),
    'completed_sessions', COUNT(DISTINCT CASE WHEN ds.status = 'completed' THEN ds.id END),
    'total_wins', COUNT(DISTINCT CASE WHEN ds.winner_id = player_id THEN ds.id END),
    'total_rounds_won', COALESCE(SUM(dp.rounds_won) FILTER (WHERE dp.user_id = player_id), 0),
    'total_cochons', COUNT(CASE WHEN dp.is_cochon THEN 1 END),
    'win_rate', ROUND(
      COALESCE(
        COUNT(DISTINCT CASE WHEN ds.winner_id = player_id THEN ds.id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT CASE WHEN ds.status = 'completed' THEN ds.id END), 0) * 100,
        0
      ),
      2
    ),
    'last_played_at', MAX(ds.completed_at)
  ) INTO stats
  FROM domino_participants dp
  LEFT JOIN domino_sessions ds ON ds.id = dp.session_id
  WHERE dp.user_id = player_id;

  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_domino_player_stats(UUID) IS 'Retourne les statistiques d''un joueur de dominos';

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Autoriser les utilisateurs authentifiés à appeler les RPC functions
GRANT EXECUTE ON FUNCTION generate_domino_join_code() TO authenticated;
GRANT EXECUTE ON FUNCTION increment_domino_rounds_won(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_domino_leaderboard(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_domino_player_stats(UUID) TO authenticated;

-- ============================================================================
-- FIN DU SCHEMA
-- ============================================================================
