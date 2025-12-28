-- ================================================
-- Ajout des champs code postal et téléphone
-- ================================================
-- Ce fichier ajoute les colonnes postal_code et phone à la table users

ALTER TABLE users
ADD COLUMN IF NOT EXISTS postal_code TEXT,
ADD COLUMN IF NOT EXISTS phone TEXT;

-- Vérification
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('postal_code', 'phone');
