# Import du dictionnaire créole vers Supabase

Ce guide explique comment importer les données du dictionnaire JSON vers la base de données Supabase.

## Prérequis

1. **Installer Node.js et npm** (si ce n'est pas déjà fait)

2. **Installer les dépendances**:
   ```bash
   cd apps/games-flutter/scripts
   npm install @supabase/supabase-js
   ```

3. **Obtenir les identifiants Supabase**:
   - Aller sur [Supabase Dashboard](https://supabase.com/dashboard)
   - Sélectionner votre projet
   - Aller dans **Settings** > **API**
   - Copier:
     - **Project URL** (ex: `https://xxxxx.supabase.co`)
     - **service_role key** (dans "Project API keys" section)

4. **Créer le schéma de base de données**:
   - Aller dans **SQL Editor** sur Supabase Dashboard
   - Créer une nouvelle requête
   - Copier le contenu de `supabase/migrations/dictionary_schema.sql`
   - Exécuter (Run)

## Import des données

### Étape 1: Définir les variables d'environnement

```bash
export SUPABASE_URL="https://xxxxx.supabase.co"
export SUPABASE_SERVICE_KEY="eyJhbGciOiJI..."
```

**💡 Pour ne pas avoir à les redéfinir à chaque fois**, créez un fichier `.env.local`:

```bash
# .env.local
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJI...
```

Puis chargez-le:
```bash
source .env.local
```

### Étape 2: Exécuter l'import

```bash
cd apps/games-flutter/scripts
node import_dictionary.js
```

### Résultat attendu

```
🔄 Import du dictionnaire créole vers Supabase...

📖 Lecture de dictionnaire_A.json...
   285 mots trouvés

✅ dictionnaire_A.json traité

═══════════════════════════════════════
📊 Résumé de l'import:
   ✅ Importés: 570
   ⏭️  Ignorés (doublons): 0
   ❌ Erreurs: 0
═══════════════════════════════════════

🎉 Import terminé avec succès!
```

**Note**: 570 entrées = 285 mots créole + 285 traductions français (traduction bidirectionnelle)

## Ajouter d'autres lettres

Pour importer d'autres fichiers dictionnaire (B, C, D, etc.):

1. Placer le fichier JSON dans `/data/dictionnaires/`
2. Modifier `import_dictionary.js` ligne 24:
   ```javascript
   const dictionnaireFiles = [
     path.join(__dirname, '../../../data/dictionnaires/dictionnaire_A.json'),
     path.join(__dirname, '../../../data/dictionnaires/dictionnaire_B.json'), // Ajouter ici
   ];
   ```
3. Ré-exécuter le script

## Vérification

Pour vérifier que l'import a fonctionné:

1. Aller sur Supabase Dashboard > **Table Editor**
2. Sélectionner la table `dictionary_words`
3. Vous devriez voir ~570 entrées

Ou via SQL:
```sql
SELECT COUNT(*) FROM dictionary_words;
```

## Dépannage

### Erreur "Variables d'environnement manquantes"
- Vérifiez que `SUPABASE_URL` et `SUPABASE_SERVICE_KEY` sont définies
- Utilisez `echo $SUPABASE_URL` pour vérifier

### Erreur "Module not found: @supabase/supabase-js"
```bash
cd apps/games-flutter/scripts
npm install @supabase/supabase-js
```

### Erreur "relation 'dictionary_words' does not exist"
- Vous devez d'abord exécuter le script SQL `dictionary_schema.sql` dans Supabase

### Doublons lors du ré-import
- Le script utilise `upsert` avec `onConflict` : les doublons sont automatiquement ignorés
- Pas de problème à ré-exécuter le script plusieurs fois

## Structure JSON attendue

Le script accepte des fichiers JSON avec cette structure:

```json
[
  {
    "mot": "ansowsèlé",
    "definitions": [
      {
        "sens_num": 1,
        "nature": "v.",
        "traduction": "passer un pacte avec le diable",
        "exemples": [
          {
            "creole": "Yo ka ansowsèlé kò-yo...",
            "francais": "Ils passent un pacte..."
          }
        ],
        "synonymes": [],
        "variantes": []
      }
    ]
  }
]
```
