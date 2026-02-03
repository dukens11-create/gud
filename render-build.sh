#!/bin/bash
set -e

echo "📦 Installing Flutter..."

# Clone Flutter SDK
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

echo "🔍 Flutter doctor..."
flutter doctor -v

echo "📥 Getting dependencies..."
flutter pub get

echo "🏗️ Building web app..."
flutter build web --release --web-renderer canvaskit

echo "✅ Build complete!"
echo "📁 Output directory: build/web"
ls -la build/web
