-- ============================================================================
-- FIX: Corriger les foreign keys pour utiliser public.users au lieu de auth.users
-- ============================================================================

-- ============================================================================
-- domino_sessions
-- ============================================================================
-- Drop les anciennes contraintes
ALTER TABLE domino_sessions
  DROP CONSTRAINT IF EXISTS domino_sessions_host_id_fkey,
  DROP CONSTRAINT IF EXISTS domino_sessions_winner_id_fkey;

-- Ajouter les nouvelles contraintes pointant vers public.users
ALTER TABLE domino_sessions
  ADD CONSTRAINT domino_sessions_host_id_fkey
    FOREIGN KEY (host_id) REFERENCES public.users(id) ON DELETE CASCADE,
  ADD CONSTRAINT domino_sessions_winner_id_fkey
    FOREIGN KEY (winner_id) REFERENCES public.users(id);

-- ============================================================================
-- domino_participants
-- ============================================================================
-- Drop l'ancienne contrainte
ALTER TABLE domino_participants
  DROP CONSTRAINT IF EXISTS domino_participants_user_id_fkey;

-- Ajouter la nouvelle contrainte pointant vers public.users
ALTER TABLE domino_participants
  ADD CONSTRAINT domino_participants_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- ============================================================================
-- domino_invitations
-- ============================================================================
-- Drop les anciennes contraintes
ALTER TABLE domino_invitations
  DROP CONSTRAINT IF EXISTS domino_invitations_inviter_id_fkey,
  DROP CONSTRAINT IF EXISTS domino_invitations_invitee_id_fkey;

-- Ajouter les nouvelles contraintes pointant vers public.users
ALTER TABLE domino_invitations
  ADD CONSTRAINT domino_invitations_inviter_id_fkey
    FOREIGN KEY (inviter_id) REFERENCES public.users(id) ON DELETE CASCADE,
  ADD CONSTRAINT domino_invitations_invitee_id_fkey
    FOREIGN KEY (invitee_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Cette requête permet de vérifier que les FK sont bien définies
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name LIKE 'domino_%'
ORDER BY tc.table_name, kcu.column_name;
