-- Table pour les mots du dictionnaire créole-français
-- Structure simplifiée : un mot peut avoir plusieurs définitions
CREATE TABLE IF NOT EXISTS dictionary_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word TEXT NOT NULL,
    language TEXT NOT NULL CHECK (language IN ('creole', 'francais')),
    translation TEXT NOT NULL,
    nature TEXT,  -- v., prep., nom., adj., etc.
    example_creole TEXT,
    example_francais TEXT,
    synonymes TEXT[], -- Array de synonymes
    variantes TEXT[], -- Array de variantes
    sens_num INTEGER DEFAULT 1,
    explication_usage TEXT,
    source TEXT,
    is_official BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(word, language, sens_num) -- Un mot peut avoir plusieurs sens
);

-- Index pour améliorer les performances de recherche
CREATE INDEX IF NOT EXISTS idx_dictionary_words_word ON dictionary_words(word);
CREATE INDEX IF NOT EXISTS idx_dictionary_words_language ON dictionary_words(language);
CREATE INDEX IF NOT EXISTS idx_dictionary_words_is_official ON dictionary_words(is_official);
CREATE INDEX IF NOT EXISTS idx_dictionary_words_word_trgm ON dictionary_words USING gin(word gin_trgm_ops);

-- Activer l'extension pg_trgm pour la recherche floue
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Table pour les contributions des utilisateurs au dictionnaire
CREATE TABLE IF NOT EXISTS dictionary_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    translation TEXT NOT NULL,
    nature TEXT,
    example TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id),
    review_notes TEXT
);

-- Index pour les contributions
CREATE INDEX IF NOT EXISTS idx_dictionary_contributions_user_id ON dictionary_contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_dictionary_contributions_status ON dictionary_contributions(status);

-- Fonction pour obtenir un mot aléatoire
CREATE OR REPLACE FUNCTION get_random_word(p_language TEXT DEFAULT NULL)
RETURNS SETOF dictionary_words
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_language IS NULL THEN
        RETURN QUERY
        SELECT * FROM dictionary_words
        WHERE is_official = true
        ORDER BY RANDOM()
        LIMIT 1;
    ELSE
        RETURN QUERY
        SELECT * FROM dictionary_words
        WHERE is_official = true
        AND language = p_language
        ORDER BY RANDOM()
        LIMIT 1;
    END IF;
END;
$$;

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_dictionary_words_updated_at
    BEFORE UPDATE ON dictionary_words
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Ajouter quelques mots d'exemple pour tester
INSERT INTO dictionary_words (word, language, translation, nature, example) VALUES
('bonjou', 'creole', 'bonjour', 'interjection', 'Bonjou tout moun !'),
('mèsi', 'creole', 'merci', 'interjection', 'Mèsi anpil pou èd-la'),
('lanmè', 'creole', 'mer', 'nom', 'An ka alé lanmè jodi-la'),
('kay', 'creole', 'maison', 'nom', 'Kay-mwen bèl'),
('manzé', 'creole', 'manger', 'verbe', 'Nou ka manzé lanmori'),
('bèl', 'creole', 'beau/belle', 'adjectif', 'Sé on bèl ti fi'),
('piti', 'creole', 'petit', 'adjectif', 'Sé on piti kay'),
('gwo', 'creole', 'gros/grand', 'adjectif', 'Sé on gwo pyébwa'),
('dlo', 'creole', 'eau', 'nom', 'Bay mwen on ti dlo souplé'),
('mwen', 'creole', 'je/moi', 'pronom', 'Mwen ka alé lékol'),
('ou', 'creole', 'tu/toi', 'pronom', 'Ou ka vini ?'),
('li', 'creole', 'il/elle/lui', 'pronom', 'Li ka dòmi'),
('nou', 'creole', 'nous', 'pronom', 'Nou ka jwé'),
('zòt', 'creole', 'vous', 'pronom', 'Zòt ka maché'),
('yo', 'creole', 'ils/elles/eux', 'pronom', 'Yo ka chanté'),
('bonjour', 'francais', 'bonjou', 'interjection', NULL),
('merci', 'francais', 'mèsi', 'interjection', NULL),
('mer', 'francais', 'lanmè', 'nom', NULL),
('maison', 'francais', 'kay', 'nom', NULL),
('manger', 'francais', 'manzé', 'verbe', NULL),
('beau', 'francais', 'bèl', 'adjectif', NULL),
('belle', 'francais', 'bèl', 'adjectif', NULL),
('petit', 'francais', 'piti', 'adjectif', NULL),
('grand', 'francais', 'gwo', 'adjectif', NULL),
('gros', 'francais', 'gwo', 'adjectif', NULL),
('eau', 'francais', 'dlo', 'nom', NULL)
ON CONFLICT DO NOTHING;

-- RLS (Row Level Security) - Lecture publique, modification par admin seulement
ALTER TABLE dictionary_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE dictionary_contributions ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut lire les mots officiels
CREATE POLICY "Anyone can read official words"
    ON dictionary_words FOR SELECT
    USING (is_official = true);

-- Seuls les administrateurs peuvent insérer/modifier/supprimer des mots
CREATE POLICY "Only admins can modify words"
    ON dictionary_words FOR ALL
    USING (auth.uid() IN (
        SELECT id FROM users WHERE role = 'admin'
    ));

-- Les utilisateurs connectés peuvent soumettre des contributions
CREATE POLICY "Authenticated users can submit contributions"
    ON dictionary_contributions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent voir leurs propres contributions
CREATE POLICY "Users can view their own contributions"
    ON dictionary_contributions FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() IN (
        SELECT id FROM users WHERE role = 'admin'
    ));

-- Seuls les administrateurs peuvent modifier/approuver/rejeter les contributions
CREATE POLICY "Only admins can modify contributions"
    ON dictionary_contributions FOR UPDATE
    USING (auth.uid() IN (
        SELECT id FROM users WHERE role = 'admin'
    ));
