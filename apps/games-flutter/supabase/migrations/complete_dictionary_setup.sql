-- ═══════════════════════════════════════════════════════════════════════
-- Migration complète pour le dictionnaire créole
-- Exécuter ce fichier unique dans Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────
-- 1. Ajouter les colonnes manquantes à dictionary_words
-- ─────────────────────────────────────────────────────────────────────
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

    -- Ajouter updated_at si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'dictionary_words' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE dictionary_words
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────
-- 2. Ajouter la contrainte UNIQUE pour l'upsert
-- ─────────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'dictionary_words_word_language_sens_num_key'
    ) THEN
        ALTER TABLE dictionary_words DROP CONSTRAINT dictionary_words_word_language_sens_num_key;
    END IF;
END $$;

ALTER TABLE dictionary_words
ADD CONSTRAINT dictionary_words_word_language_sens_num_key
UNIQUE (word, language, sens_num);

-- ─────────────────────────────────────────────────────────────────────
-- 3. Ajouter la colonne role à la table users
-- ─────────────────────────────────────────────────────────────────────
DO $$
BEGIN
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

-- ─────────────────────────────────────────────────────────────────────
-- 4. Ajouter les policies pour les admins et contributeurs
-- ─────────────────────────────────────────────────────────────────────

-- Supprimer les anciennes policies si elles existent
DROP POLICY IF EXISTS "Admins can insert words" ON dictionary_words;
DROP POLICY IF EXISTS "Admins can update words" ON dictionary_words;
DROP POLICY IF EXISTS "Admins can delete words" ON dictionary_words;
DROP POLICY IF EXISTS "Contributors can view all contributions" ON dictionary_contributions;
DROP POLICY IF EXISTS "Admins can update contributions" ON dictionary_contributions;

-- Les admins peuvent insérer des mots
CREATE POLICY "Admins can insert words"
    ON dictionary_words FOR INSERT
    WITH CHECK (
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'admin'
        )
    );

-- Les admins peuvent modifier des mots
CREATE POLICY "Admins can update words"
    ON dictionary_words FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'admin'
        )
    );

-- Les admins peuvent supprimer des mots
CREATE POLICY "Admins can delete words"
    ON dictionary_words FOR DELETE
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'admin'
        )
    );

-- Les contributeurs et admins peuvent voir leurs contributions
CREATE POLICY "Contributors can view all contributions"
    ON dictionary_contributions FOR SELECT
    USING (
        auth.uid() = user_id OR
        auth.uid() IN (SELECT id FROM users WHERE role IN ('admin', 'contributor'))
    );

-- Les admins peuvent approuver/rejeter les contributions
CREATE POLICY "Admins can update contributions"
    ON dictionary_contributions FOR UPDATE
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role = 'admin'
        )
    );

-- ═══════════════════════════════════════════════════════════════════════
-- ✅ Migration complète terminée!
--
-- Prochaines étapes:
-- 1. Promouvoir un utilisateur en admin:
--    UPDATE users SET role = 'admin' WHERE email = 'votre-email@example.com';
--
-- 2. Lancer l'import du dictionnaire:
--    node scripts/import_dictionary.js
-- ═══════════════════════════════════════════════════════════════════════
