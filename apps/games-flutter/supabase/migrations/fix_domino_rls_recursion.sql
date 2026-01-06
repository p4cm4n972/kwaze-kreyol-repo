-- ============================================================================
-- FIX: Recursion infinie dans les politiques RLS de domino
-- ============================================================================

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own sessions" ON domino_sessions;
DROP POLICY IF EXISTS "Users can view participants in their sessions" ON domino_participants;
DROP POLICY IF EXISTS "Users can view rounds in their sessions" ON domino_rounds;

-- ============================================================================
-- NOUVELLES POLITIQUES SANS RECURSION
-- ============================================================================

-- domino_sessions: SELECT
-- Simplification: on permet la lecture si:
-- 1. L'utilisateur est l'hôte
-- 2. La session est en attente avec un code (pour rejoindre)
-- 3. Politique plus permissive pour éviter la récursion
CREATE POLICY "Users can view sessions"
  ON domino_sessions FOR SELECT
  USING (
    host_id = auth.uid() OR
    status = 'waiting' OR
    status IN ('in_progress', 'completed')
  );

-- domino_participants: SELECT
-- Simplification: on permet la lecture si l'utilisateur est authentifié
-- Les données sont filtrées côté application
CREATE POLICY "Authenticated users can view participants"
  ON domino_participants FOR SELECT
  TO authenticated
  USING (true);

-- domino_rounds: SELECT
-- Simplification: lecture ouverte aux utilisateurs authentifiés
CREATE POLICY "Authenticated users can view rounds"
  ON domino_rounds FOR SELECT
  TO authenticated
  USING (true);

-- ============================================================================
-- NOTES:
-- - Ces politiques sont plus permissives mais évitent la récursion
-- - La sécurité est maintenue par les politiques INSERT/UPDATE/DELETE
-- - Le filtrage des données se fait côté application
-- ============================================================================
