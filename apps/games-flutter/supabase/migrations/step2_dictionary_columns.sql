-- ÉTAPE 2: Ajouter les colonnes au dictionnaire
-- Exécutez après step1_add_role_column.sql

-- Ajouter example_creole
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS example_creole TEXT;

-- Ajouter example_francais
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS example_francais TEXT;

-- Ajouter synonymes
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS synonymes TEXT[];

-- Ajouter variantes
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS variantes TEXT[];

-- Ajouter sens_num
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS sens_num INTEGER DEFAULT 1;

-- Ajouter explication_usage
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS explication_usage TEXT;

-- Ajouter updated_at
ALTER TABLE dictionary_words ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Supprimer l'ancienne contrainte si elle existe
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

-- Vérifier que ça a fonctionné
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'dictionary_words'
  AND column_name IN ('example_creole', 'synonymes', 'variantes', 'sens_num', 'updated_at')
ORDER BY column_name;
