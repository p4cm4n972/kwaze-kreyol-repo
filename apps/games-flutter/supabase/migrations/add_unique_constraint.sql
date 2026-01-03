-- Migration: Ajouter la contrainte UNIQUE manquante
-- Cette contrainte permet d'éviter les doublons et active l'upsert

-- Supprimer la contrainte si elle existe déjà (pour éviter les erreurs)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'dictionary_words_word_language_sens_num_key'
    ) THEN
        ALTER TABLE dictionary_words DROP CONSTRAINT dictionary_words_word_language_sens_num_key;
    END IF;
END $$;

-- Ajouter la contrainte UNIQUE
ALTER TABLE dictionary_words
ADD CONSTRAINT dictionary_words_word_language_sens_num_key
UNIQUE (word, language, sens_num);
