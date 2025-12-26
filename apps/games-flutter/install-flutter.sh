#!/bin/bash
set -e

echo "📦 Installing Flutter..."

# Download Flutter
if [ ! -d "flutter" ]; then
  wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
  tar xf flutter_linux_3.24.5-stable.tar.xz
  rm flutter_linux_3.24.5-stable.tar.xz
fi

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Disable analytics
flutter config --no-analytics

# Get dependencies
flutter pub get

echo "✅ Flutter installed!"
