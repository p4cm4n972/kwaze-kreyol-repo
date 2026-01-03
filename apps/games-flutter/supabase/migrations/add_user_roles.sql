-- Migration: Ajouter la colonne role à la table users
-- Rôles disponibles:
--   - register: utilisateur en cours d'inscription (non confirmé)
--   - user: utilisateur normal
--   - contributor: peut proposer des mots au dictionnaire
--   - admin: administrateur (peut modifier le dictionnaire)

DO $$
BEGIN
    -- Ajouter role si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'role'
    ) THEN
        -- Ajouter la colonne sans contrainte NOT NULL d'abord
        ALTER TABLE users ADD COLUMN role TEXT;

        -- Mettre à jour tous les utilisateurs existants avec le role 'user'
        UPDATE users SET role = 'user' WHERE role IS NULL;

        -- Maintenant ajouter la contrainte NOT NULL et le CHECK
        ALTER TABLE users
        ALTER COLUMN role SET NOT NULL,
        ALTER COLUMN role SET DEFAULT 'user',
        ADD CONSTRAINT users_role_check CHECK (role IN ('register', 'user', 'contributor', 'admin'));

        -- Créer un index pour optimiser les requêtes par role
        CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
    END IF;
END $$;

-- Exemples de promotion de rôles:
-- UPDATE users SET role = 'contributor' WHERE id = 'user-id-1';
-- UPDATE users SET role = 'admin' WHERE id = 'user-id-2';
