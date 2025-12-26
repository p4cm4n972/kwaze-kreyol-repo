#!/bin/bash
set -e

echo "📦 Installing Flutter..."

# Clone Flutter from stable channel (gets latest stable version)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter from stable channel..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Run flutter doctor to download Dart SDK and dependencies
echo "Running flutter doctor..."
flutter doctor

# Disable analytics
flutter config --no-analytics

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

echo "✅ Flutter installed!"
echo "Flutter version:"
flutter --version
