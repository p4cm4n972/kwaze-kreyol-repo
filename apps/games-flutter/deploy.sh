#!/bin/bash
# Script de build et déploiement Flutter Web vers Vercel

echo "🚀 Build et déploiement Kwazé Kréyol Games"
echo ""

# 1. Build Flutter
echo "📦 Building Flutter web..."
flutter build web --release --web-renderer canvaskit

if [ $? -ne 0 ]; then
    echo "❌ Build Flutter failed"
    exit 1
fi

echo "✅ Build Flutter réussi"
echo ""

# 2. Déployer sur Vercel
echo "🌐 Déploiement sur Vercel..."

# Installer Vercel CLI si nécessaire
if ! command -v vercel &> /dev/null; then
    echo "📥 Installation de Vercel CLI..."
    npm install -g vercel
fi

# Déployer
vercel --prod

echo ""
echo "✅ Déploiement terminé!"
