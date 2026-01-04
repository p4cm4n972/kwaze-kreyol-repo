# 🚀 Test de déploiement avec validation des tests

## Étapes pour tester le déploiement

### Option 1 : Test local (RECOMMANDÉ pour commencer)

Simulez le processus de déploiement localement :

```bash
cd apps/games-flutter

# Exécuter le script de déploiement localement
bash scripts/cf-pages-flutter-web.sh
```

**Ce qui va se passer :**
1. ✅ Installation/vérification de Flutter
2. 🧪 Exécution des tests unitaires
3. 🧪 Exécution des tests d'intégration
4. 🚀 Build de production (si tests OK)

**Résultats attendus :**

✅ **Succès** :
```
🧪 Exécution des tests avant le déploiement...
================================================

1️⃣  Tests unitaires (modèles et logique)
00:02 +15: All tests passed!

2️⃣  Tests d'intégration (détection d'anomalies)
00:01 +10: All tests passed!

✅ Tous les tests sont passés avec succès!

🚀 Démarrage du build pour production...
========================================

Building web application...
✓ Built build/web

✅ Build terminé avec succès!
   Les tests ont validé la qualité du code.
```

❌ **Échec (si bug détecté)** :
```
1️⃣  Tests unitaires (modèles et logique)
00:01 +12 -1: Some tests failed.

✗ ANOMALIE DÉTECTÉE: Il devrait y avoir 1 manche, pas 3

❌ ERREUR: Les tests unitaires ont échoué!
   Le déploiement est annulé.
```

### Option 2 : Test via Cloudflare Pages

#### Méthode A : Push sur une branche de test

```bash
# Créer une branche de test
git checkout -b test-deploy-with-tests

# Commit des changements
git add .
git commit -m "test: Ajouter validation des tests au déploiement"

# Push vers GitHub
git push origin test-deploy-with-tests
```

Ensuite dans Cloudflare Pages :
1. Allez dans votre projet
2. Settings → Builds & deployments
3. Créez un déploiement de prévisualisation pour la branche `test-deploy-with-tests`
4. Observez les logs du build

#### Méthode B : Déploiement sur la branche principale

⚠️ **ATTENTION** : À faire seulement après avoir testé localement !

```bash
# S'assurer d'être sur main
git checkout main

# Merger les changements
git merge test-deploy-with-tests

# Push
git push origin main
```

## 📊 Vérifier les logs Cloudflare Pages

Dans Cloudflare Pages, vous verrez :

### 1. Initialisation
```
Cloning repository...
Installing Flutter...
```

### 2. Exécution des tests
```
🧪 Exécution des tests avant le déploiement...
1️⃣  Tests unitaires (modèles et logique)
Running tests...
```

### 3. Résultat

**Si les tests passent :**
```
✅ Tous les tests sont passés avec succès!
🚀 Démarrage du build pour production...
Build completed successfully
```

**Si les tests échouent :**
```
❌ ERREUR: Les tests ont échoué!
Build failed
Exit code: 1
```

## 🐛 Débogage en cas de problème

### Problème 1 : "flutter: command not found"
**Cause** : Flutter n'est pas installé correctement

**Solution** : Vérifier que le script clone bien Flutter
```bash
FLUTTER_HOME="$HOME/flutter"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi
```

### Problème 2 : "Test file not found"
**Cause** : Les fichiers de tests n'existent pas

**Solution** : Vérifier que les fichiers sont bien committés
```bash
git ls-files | grep test/met_double
# Doit afficher :
# test/met_double_test.dart
# test/met_double_integration_test.dart
```

### Problème 3 : Tests échouent localement mais pas en dev
**Cause** : Des bugs sont présents dans le code

**Solution** :
1. Regarder quel test échoue exactement
2. Lire le message d'erreur
3. Corriger le bug dans le code
4. Relancer les tests

### Problème 4 : Build réussit mais tests non exécutés
**Cause** : Erreur dans le script

**Solution** : Vérifier les logs et s'assurer que les lignes de tests apparaissent

## ✅ Checklist avant déploiement en production

- [ ] Tests locaux passent (unitaires + intégration)
- [ ] Build local réussit
- [ ] Test sur branche de prévisualisation
- [ ] Vérification des logs Cloudflare
- [ ] Pas d'erreur dans la console
- [ ] L'application fonctionne après déploiement

## 🎯 Test rapide du pipeline complet

Exécutez cette commande pour simuler le pipeline :

```bash
cd apps/games-flutter

# Nettoyer
flutter clean

# Installer les dépendances
flutter pub get

# Tests unitaires
echo "🧪 Tests unitaires..."
flutter test test/met_double_test.dart || { echo "❌ Tests unitaires échoués"; exit 1; }

# Tests d'intégration
echo "🧪 Tests d'intégration..."
flutter test test/met_double_integration_test.dart || { echo "❌ Tests intégration échoués"; exit 1; }

# Build
echo "🚀 Build production..."
flutter build web --release

echo "✅ Pipeline complet réussi!"
```

## 📝 Notes importantes

1. **Les tests ajoutent ~10-30 secondes** au temps de déploiement
2. **C'est normal et souhaitable** - meilleur d'avoir un déploiement légèrement plus lent mais sans bugs
3. **Si un test échoue**, le déploiement s'arrête immédiatement
4. **Gardez les logs** pour déboguer si nécessaire

## 🔄 Workflow recommandé

```
Développement local
    ↓
Tests locaux (./run_tests.sh)
    ↓
Commit + Push
    ↓
CI/CD Cloudflare (avec tests)
    ↓
Déploiement (si tests OK)
    ↓
Production ✅
```
