# Kwazé Kréyol Games - Flutter

Application Flutter multi-plateforme pour les jeux Kwazé Kréyol.

## 🎮 Jeux disponibles

- **Mots Mawon** : Jeu de mots cachés en créole martiniquais

## 🏗️ Architecture

```
lib/
├── games/              # Tous les jeux
│   └── mots_mawon/    # Jeu Mots Mawon
├── models/            # Modèles de données
├── services/          # Services (dictionnaire, etc.)
├── utils/             # Utilitaires (générateurs, etc.)
├── widgets/           # Widgets réutilisables
└── main.dart          # Point d'entrée
```

## 🚀 Déploiement sur Vercel

### Méthode 1 : Script automatique (Recommandé)

```bash
# Build et déployer en une commande
./deploy.sh
```

### Méthode 2 : Étape par étape

#### 1. Installer Vercel CLI

```bash
npm install -g vercel
```

#### 2. Build Flutter

```bash
flutter build web --release
```

#### 3. Se connecter à Vercel

```bash
vercel login
```

#### 4. Déployer

**Première fois (configuration) :**
```bash
vercel
```

Répondre aux questions :
- Set up and deploy? **Yes**
- Which scope? **Votre compte**
- Link to existing project? **No**
- Project name? **kwaze-kreyol-games**
- Directory? **./build/web** (IMPORTANT!)
- Override settings? **No**

**Déploiements suivants :**
```bash
# Preview
vercel

# Production
vercel --prod
```

### Méthode 3 : Via GitHub (CI/CD)

Créer `.github/workflows/deploy.yml` :

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.5'

      - name: Build Flutter Web
        run: |
          cd apps/games-flutter
          flutter pub get
          flutter build web --release

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: apps/games-flutter/build/web
          vercel-args: '--prod'
```

## 🌐 Configuration du domaine

### Sous-domaine personnalisé

1. Aller sur [Vercel Dashboard](https://vercel.com/dashboard)
2. Sélectionner votre projet
3. Settings → Domains
4. Ajouter : `games.kwaze-kreyol.com`
5. Configurer DNS :
   - Type: `CNAME`
   - Name: `games`
   - Value: `cname.vercel-dns.com`

### Intégration avec Next.js

**Option A : Redirection**
```tsx
// apps/web-vitrine/app/play/page.tsx
const games = [
  {
    id: 'mots-mawon',
    playOnlineUrl: 'https://games.kwaze-kreyol.com/mots-mawon',
    // ...
  }
];
```

**Option B : Iframe**
```tsx
<iframe
  src="https://games.kwaze-kreyol.com"
  width="100%"
  height="800px"
  frameBorder="0"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
/>
```

## 📦 Build

### Web

```bash
flutter build web --release
```

Le renderer web est automatiquement optimisé selon le navigateur (CanvasKit pour les navigateurs modernes).

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 📊 Données partagées

Le dictionnaire est centralisé dans `/data/dictionnaires/` au niveau du monorepo.

Pour la version web, il faudra héberger les fichiers JSON ou les charger via une API.

## 🛠️ Développement

### Installer les dépendances

```bash
flutter pub get
```

### Lancer en mode dev

```bash
# Web
flutter run -d chrome

# Android
flutter run

# iOS (macOS uniquement)
flutter run -d iphone
```

### Tests

```bash
flutter test
```

## 🐛 Troubleshooting

### Erreur CORS lors du chargement du dictionnaire

Modifier `web/index.html` pour ajouter les headers CORS :

```html
<meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
<meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
```

### Build web ne fonctionne pas

```bash
flutter clean
flutter pub get
flutter build web --release
```

## 📱 Apps mobiles

### Google Play Store

1. Build APK : `flutter build apk --release`
2. Créer un compte développeur Google Play
3. Upload l'APK sur Play Console

### Apple App Store

1. Build iOS : `flutter build ios --release`
2. Ouvrir Xcode : `open ios/Runner.xcworkspace`
3. Archive et upload via Xcode
4. Soumettre sur App Store Connect

## 🔧 Variables d'environnement (optionnel)

Pour la prod, créer `.env` :

```env
DICTIONARY_API_URL=https://api.kwaze-kreyol.com/dictionaries
```

## 📄 License

ITMade Studio © 2025
