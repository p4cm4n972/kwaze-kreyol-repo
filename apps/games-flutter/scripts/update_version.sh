#!/bin/bash
# Script pour mettre à jour le numéro de version basé sur le nombre de commits git
# Format: Beta 1.XXX où XXX = nombre de commits depuis le tag v1.0.0-beta.1
# Usage: Exécuté automatiquement via le hook pre-push

cd "$(dirname "$0")/.." || exit 1

VERSION_FILE="lib/core/app_version.dart"

# Compter les commits depuis le tag v1.0.0-beta.1 (ou depuis le début si tag absent)
if git rev-parse v1.0.0-beta.1 >/dev/null 2>&1; then
  COMMITS_SINCE_BETA=$(git rev-list v1.0.0-beta.1..HEAD --count)
else
  # Fallback: compter tous les commits
  COMMITS_SINCE_BETA=$(git rev-list --count HEAD)
fi

# Formater avec zéros (ex: 001, 012, 123)
FORMATTED_VERSION=$(printf "%03d" "$COMMITS_SINCE_BETA")

# Mettre à jour le fichier
cat > "$VERSION_FILE" << EOF
/// Version de l'application
/// Mis à jour automatiquement via le hook pre-push
class AppVersion {
  static const String version = '1.0.0';
  static const String stage = 'beta.1';
  static const int patchNumber = $COMMITS_SINCE_BETA;

  /// Version complète formatée pour l'affichage
  static String get fullVersion => 'Beta 1.$FORMATTED_VERSION';

  /// Version courte
  static String get shortVersion => version;

  /// Version sémantique complète
  static String get semver => '\$version-\$stage+\$patchNumber';
}
EOF

echo "✅ Version mise à jour: Beta 1.$FORMATTED_VERSION ($COMMITS_SINCE_BETA commits depuis beta.1)"
