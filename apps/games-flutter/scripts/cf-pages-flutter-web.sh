#!/usr/bin/env bash
set -euo pipefail

# === DIAGNOSTIC CI ===
echo "[CI] Demarrage build CF Pages - $(date -u)"
echo "[CI] CWD: $(pwd)"
echo "[CI] HOME: $HOME"
echo "[CI] uname: $(uname -a)"

# Desactiver les prompts interactifs Flutter
export CI=true
export FLUTTER_CLI_TELEMETRY=false
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

FLUTTER_HOME="$HOME/flutter"
REQUIRED_FLUTTER_VERSION="3.44.2"

# Supprimer le SDK en cache s'il n'est pas a la bonne version
if [ -d "$FLUTTER_HOME" ]; then
  CACHED_VERSION=$("$FLUTTER_HOME/bin/flutter" --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
  echo "[CI] Flutter en cache: $CACHED_VERSION (requis: $REQUIRED_FLUTTER_VERSION)"
  if [ "$CACHED_VERSION" != "$REQUIRED_FLUTTER_VERSION" ]; then
    echo "[CI] Version differente - suppression du cache Flutter..."
    rm -rf "$FLUTTER_HOME"
  fi
fi

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "[CI] Clonage de Flutter $REQUIRED_FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "[CI] === Flutter version ==="
flutter --version
flutter config --no-analytics
flutter config --enable-web

echo "[CI] === Purge .dart_tool/flutter_build/ ==="
rm -rf .dart_tool/flutter_build/

echo "[CI] === flutter pub get ==="
flutter pub get

echo "[CI] === Tests unitaires ==="
if ! flutter test test/met_double_test.dart; then
  echo "[CI] ERREUR: Tests unitaires echoues. Deploiement annule."
  exit 1
fi

echo "[CI] === Tests integration ==="
if ! flutter test test/met_double_integration_test.dart; then
  echo "[CI] ERREUR: Tests integration echoues. Deploiement annule."
  exit 1
fi

echo "[CI] === Build web release (O2) ==="
flutter build web --release --no-wasm-dry-run --dart2js-optimization=O2

# Fichier de diagnostic pour verifier quel commit est deploye
echo "commit=${CF_PAGES_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}" > build/web/build-info.txt
echo "branch=${CF_PAGES_BRANCH:-main}" >> build/web/build-info.txt
echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> build/web/build-info.txt
flutter --version 2>/dev/null | head -1 >> build/web/build-info.txt
echo "app_version=Beta 1.025" >> build/web/build-info.txt

echo "[CI] === Build termine avec succes! ==="
echo "[CI] build-info.txt:"
cat build/web/build-info.txt
