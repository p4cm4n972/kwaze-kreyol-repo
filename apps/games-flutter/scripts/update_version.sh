#!/bin/bash
# Script pour mettre à jour le numéro de version basé sur le nombre de commits git
# Usage: ./scripts/update_version.sh (à exécuter avant chaque push)

cd "$(dirname "$0")/.." || exit 1

VERSION_FILE="lib/core/app_version.dart"

# Compter les commits git (on ajoute +1 car le commit actuel n'est pas encore fait)
COMMIT_COUNT=$(git rev-list --count HEAD)
NEXT_COUNT=$((COMMIT_COUNT + 1))

# Mettre à jour le fichier
cat > "$VERSION_FILE" << EOF
/// Version de l'application
/// Le numéro correspond au nombre de commits git
/// Mis à jour via le script update_version.sh avant chaque push
class AppVersion {
  static const int commitCount = $NEXT_COUNT;

  /// Version complète formatée pour l'affichage
  static String get fullVersion => 'Beta 0.\$commitCount';

  /// Version courte
  static String get shortVersion => '0.\$commitCount';
}
EOF

echo "✅ Version mise à jour: Beta 0.$NEXT_COUNT"
