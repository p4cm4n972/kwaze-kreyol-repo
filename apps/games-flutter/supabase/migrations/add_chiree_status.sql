-- ============================================================================
-- AJOUT DU STATUS 'CHIREE' POUR LES DOMINOS
-- ============================================================================
-- Permet de terminer une partie en match nul quand tous les joueurs
-- ont gagné au moins 1 manche
-- ============================================================================

-- Supprimer l'ancienne contrainte CHECK sur le status
ALTER TABLE domino_sessions
DROP CONSTRAINT IF EXISTS domino_sessions_status_check;

-- Ajouter la nouvelle contrainte CHECK avec 'chiree'
ALTER TABLE domino_sessions
ADD CONSTRAINT domino_sessions_status_check
CHECK (status IN ('waiting', 'in_progress', 'completed', 'cancelled', 'chiree'));
