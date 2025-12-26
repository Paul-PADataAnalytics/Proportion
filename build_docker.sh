#!/bin/bash
set -e

echo "Cleaning previous builds..."
flutter clean

echo "Building Flutter Web App (Release Mode)..."
flutter build web --release

echo "Building Docker Container..."
docker build -t proportion_app .

echo "-------------------------------------------------------"
echo "Build Complete!"
echo "To run your app, execute:"
echo "docker run -p 8080:80 proportion_app"
echo "Then open http://localhost:8080 in your browser."
