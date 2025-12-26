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

## 🚀 Build

### Web (pour intégration dans le site Next.js)

```bash
flutter build web --release
```

Le build sera dans `build/web/`

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 🔗 Intégration avec Next.js

### Option 1: Déploiement séparé (Recommandé)

1. Build le projet Flutter web
2. Déployer sur un sous-domaine (ex: games.kwaze-kreyol.com)
3. Le site Next.js redirige vers ce sous-domaine

### Option 2: Iframe

```tsx
<iframe
  src="https://games.kwaze-kreyol.com/mots-mawon"
  width="100%"
  height="800px"
  frameBorder="0"
/>
```

### Option 3: Build dans public/

1. Build Flutter web
2. Copier `build/web/*` vers `../web-vitrine/public/games/`
3. Accès via `https://kwaze-kreyol.com/games/index.html`

## 📊 Données partagées

Le dictionnaire est centralisé dans `/data/dictionnaires/` au niveau du monorepo.

## 🛠️ Développement

### Installer les dépendances

```bash
flutter pub get
```

### Lancer en mode dev

```bash
# Web
flutter run -d chrome

# Android/iOS
flutter run
```
