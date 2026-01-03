-- ÉTAPE 1: Créer UNIQUEMENT la colonne role
-- Exécutez ce script en premier

-- Ajouter la colonne role sans contrainte
ALTER TABLE users ADD COLUMN IF NOT EXISTS role TEXT;

-- Mettre à jour tous les utilisateurs existants
UPDATE users SET role = 'user' WHERE role IS NULL;

-- Ajouter les contraintes
ALTER TABLE users
  ALTER COLUMN role SET DEFAULT 'user';

-- Ajouter la contrainte CHECK (seulement si elle n'existe pas)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_role_check'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_role_check
      CHECK (role IN ('register', 'user', 'contributor', 'admin'));
  END IF;
END $$;

-- Créer l'index
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Vérifier que ça a fonctionné
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'role';
