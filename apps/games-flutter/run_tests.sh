#!/bin/bash

# Script pour exécuter les tests Met Double
# Usage: ./run_tests.sh [option]
#
# Options:
#   all         - Tous les tests (par défaut)
#   anomalies   - Tests de détection d'anomalies uniquement
#   unit        - Tests unitaires uniquement
#   verbose     - Mode verbose avec détails

set -e

cd "$(dirname "$0")"

echo "🎮 Tests Met Double - Kwaze Kreyol"
echo "=================================="
echo ""

case "${1:-all}" in
  anomalies)
    echo "🔍 Exécution des tests de détection d'anomalies..."
    echo "   Ces tests détectent les bugs d'enregistrement multiple"
    echo ""
    flutter test test/met_double_integration_test.dart
    ;;

  unit)
    echo "📝 Exécution des tests unitaires..."
    echo ""
    flutter test test/met_double_test.dart
    ;;

  verbose)
    echo "🔍 Exécution des tests en mode VERBOSE..."
    echo "   (affiche les détails de chaque test)"
    echo ""
    flutter test test/met_double_integration_test.dart --verbose
    ;;

  coverage)
    echo "📊 Exécution des tests avec couverture de code..."
    echo ""
    flutter test --coverage
    echo ""
    echo "✅ Rapport de couverture généré dans: coverage/lcov.info"
    ;;

  all|*)
    echo "🚀 Exécution de tous les tests Met Double..."
    echo ""
    echo "1️⃣  Tests unitaires (modèles et logique)"
    flutter test test/met_double_test.dart
    echo ""
    echo "2️⃣  Tests d'intégration (détection d'anomalies)"
    flutter test test/met_double_integration_test.dart
    ;;
esac

echo ""
echo "✅ Tests terminés !"
echo ""
echo "💡 Conseils:"
echo "   - Si un test échoue avec 'ANOMALIE DÉTECTÉE', c'est un bug à corriger"
echo "   - Si un test échoue avec 'BUG RÉGRESSION', un bug précédemment corrigé est revenu"
echo "   - Utilisez --verbose pour voir plus de détails sur les échecs"
