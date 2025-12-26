#!/bin/bash
set -e

echo "🚀 Starting Flutter development server..."

# Check if Flutter is already installed
if [ ! -d "flutter" ]; then
  echo "Flutter not found locally. Installing..."
  ./install-flutter.sh
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Install dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Launch dev server on Chrome
echo "🌐 Launching Flutter web app on Chrome..."
echo "🔥 Hot reload enabled - press 'r' to reload, 'R' for full restart, 'q' to quit"
flutter run -d chrome

