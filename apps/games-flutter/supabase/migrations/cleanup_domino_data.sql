-- ============================================================================
-- CLEANUP: Nettoyer toutes les données de domino pour repartir à zéro
-- ============================================================================

-- Supprimer toutes les données (les contraintes CASCADE vont tout nettoyer)
DELETE FROM domino_sessions;

-- Vérification
SELECT 'domino_sessions' as table_name, COUNT(*) as row_count FROM domino_sessions
UNION ALL
SELECT 'domino_participants', COUNT(*) FROM domino_participants
UNION ALL
SELECT 'domino_rounds', COUNT(*) FROM domino_rounds
UNION ALL
SELECT 'domino_invitations', COUNT(*) FROM domino_invitations;
