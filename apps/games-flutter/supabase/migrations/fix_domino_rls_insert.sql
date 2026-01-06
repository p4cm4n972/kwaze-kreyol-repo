-- ============================================================================
-- FIX: Simplifier les politiques INSERT pour éviter les sous-requêtes
-- ============================================================================

-- Supprimer l'ancienne politique INSERT restrictive
DROP POLICY IF EXISTS "Users can join sessions" ON domino_participants;

-- Nouvelle politique INSERT simple - les utilisateurs authentifiés peuvent s'insérer
CREATE POLICY "Authenticated users can join sessions"
  ON domino_participants FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- ============================================================================
-- NOTES:
-- - Politique très permissive pour INSERT
-- - La validation métier se fait côté application
-- - Simplifie le code et évite les récursions RLS
-- ============================================================================
