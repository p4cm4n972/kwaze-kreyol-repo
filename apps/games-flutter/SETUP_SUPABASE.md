# Configuration Supabase et Firebase pour Kwazé Kréyol

Ce document explique comment configurer Supabase et Firebase pour l'application Flutter.

## 1. Configuration Supabase

### 1.1 Créer un projet Supabase

1. Connectez-vous à [supabase.com](https://supabase.com) avec votre compte existant (learning.itmade.fr)
2. Créez un nouveau projet ou utilisez un projet existant
3. Notez les informations suivantes dans Project Settings > API:
   - `Project URL` (ex: https://xxxxx.supabase.co)
   - `anon public` key

### 1.2 Créer le fichier de configuration

Créez le fichier `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'VOTRE_URL_SUPABASE';
  static const String supabaseAnonKey = 'VOTRE_ANON_KEY';
}
```

**IMPORTANT:** Ajoutez ce fichier au .gitignore pour ne pas exposer vos clés.

### 1.3 Schéma de base de données

Exécutez les scripts SQL suivants dans l'éditeur SQL de Supabase:

#### Tables principales

```sql
-- Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table users (étendue depuis auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  username TEXT,
  avatar_url TEXT,
  fcm_token TEXT, -- Pour les notifications push
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table sessions Mét Double
CREATE TABLE met_double_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  host_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'waiting', -- waiting, in_progress, completed, cancelled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  winner_id UUID REFERENCES users(id),
  winner_name TEXT, -- Pour les invités
  total_rounds INTEGER DEFAULT 0
);

-- Table participants (avec support invités)
CREATE TABLE met_double_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES met_double_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id), -- NULL si invité
  guest_name TEXT, -- NULL si utilisateur inscrit
  victories INTEGER DEFAULT 0,
  is_cochon BOOLEAN DEFAULT FALSE,
  is_host BOOLEAN DEFAULT FALSE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Contrainte: soit user_id soit guest_name doit être non-NULL
  CONSTRAINT user_or_guest_check CHECK (
    (user_id IS NOT NULL AND guest_name IS NULL) OR
    (user_id IS NULL AND guest_name IS NOT NULL)
  )
);

-- Table rounds (manches)
CREATE TABLE met_double_rounds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES met_double_sessions(id) ON DELETE CASCADE,
  round_number INTEGER NOT NULL,
  winner_participant_id UUID REFERENCES met_double_participants(id),
  is_chiree BOOLEAN DEFAULT FALSE,
  recorded_by_user_id UUID REFERENCES users(id), -- Qui a enregistré le résultat
  played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table invitations
CREATE TABLE met_double_invitations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES met_double_sessions(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES users(id),
  invitee_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending', -- pending, accepted, declined
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE
);

-- Table dictionnaire
CREATE TABLE dictionary_words (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  word TEXT NOT NULL,
  language TEXT NOT NULL, -- 'creole' ou 'francais'
  translation TEXT NOT NULL,
  nature TEXT, -- Nom, verbe, adjectif, etc.
  example TEXT,
  source TEXT,
  is_official BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour la recherche
CREATE INDEX idx_dictionary_word ON dictionary_words(word);
CREATE INDEX idx_dictionary_language ON dictionary_words(language);

-- Table contributions dictionnaire
CREATE TABLE dictionary_contributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id),
  word TEXT NOT NULL,
  translation TEXT NOT NULL,
  nature TEXT,
  example TEXT,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, approved, rejected
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES users(id),
  review_notes TEXT
);
```

#### Fonctions PostgreSQL

```sql
-- Fonction pour incrémenter les victoires d'un participant
CREATE OR REPLACE FUNCTION increment_participant_victories(participant_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE met_double_participants
  SET victories = victories + 1
  WHERE id = participant_id;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les cochons donnés par un joueur
CREATE OR REPLACE FUNCTION get_cochons_donnes(player_id UUID)
RETURNS TABLE (
  victim_id UUID,
  victim_name TEXT,
  session_id UUID,
  completed_at TIMESTAMP WITH TIME ZONE,
  total_rounds INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.user_id as victim_id,
    COALESCE(u.username, p.guest_name) as victim_name,
    s.id as session_id,
    s.completed_at,
    s.total_rounds
  FROM met_double_sessions s
  JOIN met_double_participants p ON p.session_id = s.id
  LEFT JOIN users u ON u.id = p.user_id
  WHERE s.status = 'completed'
    AND p.is_cochon = TRUE
    AND s.winner_id = player_id
  ORDER BY s.completed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les cochons reçus par un joueur
CREATE OR REPLACE FUNCTION get_cochons_recus(victim_id UUID)
RETURNS TABLE (
  player_id UUID,
  player_name TEXT,
  session_id UUID,
  completed_at TIMESTAMP WITH TIME ZONE,
  total_rounds INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.winner_id as player_id,
    winner.username as player_name,
    s.id as session_id,
    s.completed_at,
    s.total_rounds
  FROM met_double_sessions s
  JOIN users winner ON winner.id = s.winner_id
  JOIN met_double_participants p ON p.session_id = s.id
  WHERE s.status = 'completed'
    AND p.is_cochon = TRUE
    AND p.user_id = victim_id
  ORDER BY s.completed_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour comparer deux joueurs
CREATE OR REPLACE FUNCTION compare_players(player1_id UUID, player2_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_sessions_played', COUNT(DISTINCT s.id),
    'player1_wins', COUNT(DISTINCT CASE WHEN s.winner_id = player1_id THEN s.id END),
    'player2_wins', COUNT(DISTINCT CASE WHEN s.winner_id = player2_id THEN s.id END),
    'player1_cochons_given', COUNT(DISTINCT CASE WHEN s.winner_id = player1_id AND p2.is_cochon THEN s.id END),
    'player2_cochons_given', COUNT(DISTINCT CASE WHEN s.winner_id = player2_id AND p1.is_cochon THEN s.id END),
    'player1_cochons_received', COUNT(DISTINCT CASE WHEN p1.is_cochon AND s.winner_id = player2_id THEN s.id END),
    'player2_cochons_received', COUNT(DISTINCT CASE WHEN p2.is_cochon AND s.winner_id = player1_id THEN s.id END),
    'last_played_at', MAX(s.completed_at)
  ) INTO result
  FROM met_double_sessions s
  JOIN met_double_participants p1 ON p1.session_id = s.id AND p1.user_id = player1_id
  JOIN met_double_participants p2 ON p2.session_id = s.id AND p2.user_id = player2_id
  WHERE s.status = 'completed';

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir un mot aléatoire
CREATE OR REPLACE FUNCTION get_random_word(p_language TEXT DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  word TEXT,
  language TEXT,
  translation TEXT,
  nature TEXT,
  example TEXT,
  source TEXT,
  is_official BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM dictionary_words
  WHERE (p_language IS NULL OR dictionary_words.language = p_language)
    AND is_official = TRUE
  ORDER BY RANDOM()
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;
```

#### Politiques RLS (Row Level Security)

```sql
-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE met_double_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE met_double_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE met_double_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE met_double_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE dictionary_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE dictionary_contributions ENABLE ROW LEVEL SECURITY;

-- Politiques users: tout le monde peut lire, seul l'utilisateur peut modifier son profil
CREATE POLICY "Users can read all profiles" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Politiques sessions: participants peuvent lire, hôte peut modifier
CREATE POLICY "Users can read sessions they participate in" ON met_double_sessions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM met_double_participants
      WHERE session_id = id AND (user_id = auth.uid() OR user_id IS NULL)
    )
  );

CREATE POLICY "Host can update session" ON met_double_sessions
  FOR UPDATE USING (host_id = auth.uid());

CREATE POLICY "Users can create sessions" ON met_double_sessions
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Politiques participants: lecture publique, modification par les participants de la session
CREATE POLICY "Anyone can read participants" ON met_double_participants FOR SELECT USING (true);
CREATE POLICY "Users can join sessions" ON met_double_participants FOR INSERT WITH CHECK (true);

-- Politiques rounds: participants peuvent créer/lire
CREATE POLICY "Participants can read rounds" ON met_double_rounds FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM met_double_participants
    WHERE session_id = met_double_rounds.session_id
      AND (user_id = auth.uid() OR user_id IS NULL)
  )
);

CREATE POLICY "Participants can create rounds" ON met_double_rounds FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM met_double_participants
    WHERE session_id = met_double_rounds.session_id
      AND user_id = auth.uid()
  )
);

-- Politiques invitations
CREATE POLICY "Users can read their invitations" ON met_double_invitations
  FOR SELECT USING (invitee_id = auth.uid() OR inviter_id = auth.uid());

CREATE POLICY "Users can send invitations" ON met_double_invitations
  FOR INSERT WITH CHECK (inviter_id = auth.uid());

CREATE POLICY "Users can update their invitations" ON met_double_invitations
  FOR UPDATE USING (invitee_id = auth.uid());

-- Politiques dictionnaire: lecture publique, seuls admins peuvent ajouter
CREATE POLICY "Anyone can read dictionary" ON dictionary_words FOR SELECT USING (true);

-- Politiques contributions: utilisateurs peuvent soumettre et lire leurs contributions
CREATE POLICY "Users can submit contributions" ON dictionary_contributions
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can read their contributions" ON dictionary_contributions
  FOR SELECT USING (user_id = auth.uid());
```

### 1.4 Realtime

Activez Realtime pour les tables suivantes dans Database > Replication:

- `met_double_sessions`
- `met_double_participants`
- `met_double_rounds`
- `met_double_invitations`

## 2. Configuration Firebase (FCM)

### 2.1 Créer un projet Firebase

1. Allez sur [console.firebase.google.com](https://console.firebase.google.com)
2. Créez un nouveau projet "Kwazé Kréyol"
3. Ajoutez une application Android et/ou iOS

### 2.2 Configuration Android

1. Téléchargez `google-services.json`
2. Placez-le dans `android/app/`
3. Modifiez `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

4. Modifiez `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### 2.3 Configuration iOS

1. Téléchargez `GoogleService-Info.plist`
2. Ajoutez-le dans Xcode au projet iOS
3. Configurez les capacités de notification push dans Xcode

### 2.4 Supabase Edge Function pour notifications

Créez une Edge Function `send-notification`:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { user_id, title, body, data } = await req.json()

  // Récupérer le FCM token de l'utilisateur
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { data: user } = await supabase
    .from('users')
    .select('fcm_token')
    .eq('id', user_id)
    .single()

  if (!user?.fcm_token) {
    return new Response(JSON.stringify({ error: 'No FCM token found' }), {
      status: 404,
    })
  }

  // Envoyer la notification via FCM (utiliser HTTP API ou Admin SDK)
  const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')

  const response = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `key=${FCM_SERVER_KEY}`,
    },
    body: JSON.stringify({
      to: user.fcm_token,
      notification: { title, body },
      data,
    }),
  })

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

## 3. Initialisation dans l'application

Modifiez `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp();

  // Initialiser Supabase
  await SupabaseService.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialiser les notifications push
  await PushNotificationService().initialize();

  runApp(const MyApp());
}
```

## 4. Variables d'environnement

Créez un fichier `.env` (déjà dans .gitignore):

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your_anon_key
FCM_SERVER_KEY=your_fcm_server_key
```

## 5. Prochaines étapes

- [ ] Créer le projet Supabase
- [ ] Exécuter les scripts SQL
- [ ] Configurer Firebase
- [ ] Créer les fichiers de configuration
- [ ] Tester l'authentification
- [ ] Tester les notifications push
