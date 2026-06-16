#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="$HOME/flutter"

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

flutter build web --release

echo ""
echo "✅ Build terminé avec succès!"
echo "   Les tests ont validé la qualité du code."
echo ""
