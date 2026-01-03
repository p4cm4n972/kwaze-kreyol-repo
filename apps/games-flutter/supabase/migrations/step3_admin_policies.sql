-- ÉTAPE 3: Créer les policies pour les admins
-- Exécutez après step1 et step2
-- IMPORTANT: La colonne role DOIT exister avant d'exécuter ce script

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

-- Vérifier que les policies ont été créées
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('dictionary_words', 'dictionary_contributions')
ORDER BY tablename, policyname;
