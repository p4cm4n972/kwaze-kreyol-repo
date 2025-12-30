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
flutter pub get
flutter build web --release
