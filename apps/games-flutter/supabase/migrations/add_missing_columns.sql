-- Migration: Ajouter les colonnes manquantes à dictionary_words
-- Exécuter ce script dans Supabase SQL Editor si la table existe déjà

-- Ajouter les colonnes manquantes si elles n'existent pas
DO $$
BEGIN
    -- Ajouter example_creole si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'example_creole'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN example_creole TEXT;
    END IF;

    -- Ajouter example_francais si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'example_francais'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN example_francais TEXT;
    END IF;

    -- Ajouter synonymes si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'synonymes'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN synonymes TEXT[];
    END IF;

    -- Ajouter variantes si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'variantes'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN variantes TEXT[];
    END IF;

    -- Ajouter sens_num si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'sens_num'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN sens_num INTEGER DEFAULT 1;
    END IF;

    -- Ajouter explication_usage si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'explication_usage'
    ) THEN
        ALTER TABLE dictionary_words ADD COLUMN explication_usage TEXT;
    END IF;
END $$;
