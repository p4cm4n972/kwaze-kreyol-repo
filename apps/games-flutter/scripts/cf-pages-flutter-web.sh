#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="$HOME/flutter"
REQUIRED_FLUTTER_VERSION="3.44.2"

# Supprimer le SDK en cache s'il n'est pas à la bonne version (CF Pages cache $HOME entre builds)
if [ -d "$FLUTTER_HOME" ]; then
  CACHED_VERSION=$("$FLUTTER_HOME/bin/flutter" --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
  if [ "$CACHED_VERSION" != "$REQUIRED_FLUTTER_VERSION" ]; then
    echo "Flutter en cache: $CACHED_VERSION — attendu: $REQUIRED_FLUTTER_VERSION. Suppression du cache."
    rm -rf "$FLUTTER_HOME"
  fi
fi

if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web

# On est déjà dans apps/games-flutter grâce au Root directory
# Purger le cache de build pour forcer la régénération du web_plugin_registrant.dart
# (évite de servir d'anciens plugins si les dépendances ont changé entre deux builds)
rm -rf .dart_tool/flutter_build/
flutter pub get

echo ""
echo "🧪 Exécution des tests avant le déploiement..."
echo "================================================"
echo ""

# Exécuter les tests Met Double
echo "1️⃣  Tests unitaires (modèles et logique)"
if ! flutter test test/met_double_test.dart; then
  echo ""
  echo "❌ ERREUR: Les tests unitaires ont échoué!"
  echo "   Le déploiement est annulé."
  echo ""
  exit 1
fi

echo ""
echo "2️⃣  Tests d'intégration (détection d'anomalies)"
if ! flutter test test/met_double_integration_test.dart; then
  echo ""
  echo "❌ ERREUR: Les tests d'intégration ont échoué!"
  echo "   Des anomalies ont été détectées."
  echo "   Le déploiement est annulé."
  echo ""
  exit 1
fi

echo ""
echo "✅ Tous les tests sont passés avec succès!"
echo ""
echo "🚀 Démarrage du build pour production..."
echo "========================================"
echo ""

flutter build web --release --no-wasm-dry-run

echo ""
echo "✅ Build terminé avec succès!"
echo "   Les tests ont validé la qualité du code."
echo ""
