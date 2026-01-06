-- ============================================================================
-- FIX: Permettre la lecture de toutes les sessions/participants sans restriction
-- ============================================================================

-- Supprimer les anciennes politiques SELECT
DROP POLICY IF EXISTS "Users can view sessions" ON domino_sessions;
DROP POLICY IF EXISTS "Authenticated users can view participants" ON domino_participants;
DROP POLICY IF EXISTS "Authenticated users can view rounds" ON domino_rounds;

-- ============================================================================
-- NOUVELLES POLITIQUES TOTALEMENT OUVERTES EN LECTURE
-- ============================================================================

-- domino_sessions: SELECT - LECTURE LIBRE
CREATE POLICY "Anyone can view sessions"
  ON domino_sessions FOR SELECT
  USING (true);

-- domino_participants: SELECT - LECTURE LIBRE
CREATE POLICY "Anyone can view participants"
  ON domino_participants FOR SELECT
  USING (true);

-- domino_rounds: SELECT - LECTURE LIBRE
CREATE POLICY "Anyone can view rounds"
  ON domino_rounds FOR SELECT
  USING (true);

-- ============================================================================
-- NOTES:
-- - Lecture totalement ouverte pour éviter les problèmes de récursion
-- - La sécurité est maintenue par les politiques INSERT/UPDATE/DELETE
-- - Pas de filtrage côté base de données pour les SELECTs
-- ============================================================================
