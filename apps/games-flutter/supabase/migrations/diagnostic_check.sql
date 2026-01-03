-- Script de diagnostic pour vérifier l'état des tables

-- Vérifier les colonnes de la table users
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Vérifier les colonnes de la table dictionary_words
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'dictionary_words'
ORDER BY ordinal_position;

-- Vérifier les contraintes sur dictionary_words
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'dictionary_words'::regclass;
