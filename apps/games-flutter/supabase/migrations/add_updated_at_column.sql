-- Migration: Ajouter la colonne updated_at manquante
-- Cette colonne est nécessaire pour le trigger de mise à jour

DO $$
BEGIN
    -- Ajouter updated_at si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE dictionary_words
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;
