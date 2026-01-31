# 🎯 Projet: Kwaze Kreyol

> **Résumé en une ligne**: Monorepo avec jeux Flutter et site vitrine Next.js pour la culture créole

---

## 📋 Contexte Projet

**Type**: Monorepo multi-apps
**Statut**: En développement

---

## 🛠️ Stack Technique

### apps/games-flutter
- **Framework**: Flutter/Dart
- **Backend**: Supabase
- **Déploiement**: Vercel (pour version web)

### apps/web-vitrine
- **Framework**: Next.js 16.1.1 + React 19
- **Styling**: Tailwind CSS 4
- **Animations**: GSAP

---

## 📁 Architecture Monorepo

```
/
├── apps/
│   ├── games-flutter/    → Jeux Flutter (dominos, etc.)
│   └── web-vitrine/      → Site vitrine Next.js + GSAP
├── packages/             → Packages partagés (vide pour l'instant)
└── data/                 → Données partagées
```

---

## 🔧 Commandes Essentielles

### apps/web-vitrine
```bash
cd apps/web-vitrine
npm install
npm run dev       # Dev server
npm run build     # Build production
```

### apps/games-flutter
```bash
cd apps/games-flutter
flutter pub get
flutter run -d web-server --web-port 8080
flutter test
```

---

## ⚠️ Points d'Attention

- **Flutter**: Voir le CLAUDE.md dans `apps/games-flutter/` pour les règles Flutter spécifiques
- **GSAP**: Animations complexes sur le site vitrine
- **Monorepo**: Bien séparer les préoccupations entre apps

---

## 🤖 Instructions Claude

- Réponses en français
- Respecter la structure monorepo
- Pour Flutter, suivre les conventions du CLAUDE.md dédié
- Ne pas mixer les dépendances entre apps
