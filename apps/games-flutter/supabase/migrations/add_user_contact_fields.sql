-- Migration: Ajouter les champs de contact au profil utilisateur
-- Ces champs permettent aux utilisateurs de compléter leurs informations
-- depuis la page de profil

DO $$
BEGIN
    -- Ajouter postal_code si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'postal_code'
    ) THEN
        ALTER TABLE users ADD COLUMN postal_code TEXT;
    END IF;

    -- Ajouter phone si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'phone'
    ) THEN
        ALTER TABLE users ADD COLUMN phone TEXT;
    END IF;
END $$;

-- Vérifier que les colonnes ont été ajoutées
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users' AND column_name IN ('postal_code', 'phone')
ORDER BY column_name;
