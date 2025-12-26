#!/bin/bash
echo "🐳 Building Flutter web with Docker..."
docker build -f Dockerfile.build -t kwaze-games-builder .
docker create --name temp-container kwaze-games-builder
docker cp temp-container:/app/build/web ./build/
docker rm temp-container
echo "✅ Build terminé dans ./build/web"
