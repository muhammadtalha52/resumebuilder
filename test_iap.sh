#!/bin/bash

# Script to build and install a signed debug build for IAP testing
# This allows testing IAP without uploading to Play Store

echo "🔧 Building signed debug APK for IAP testing..."

# Clean previous builds
flutter clean

# Build debug APK (will use release signing from build.gradle)
flutter build apk --debug

# Install on connected device
echo "📱 Installing on device..."
adb install -r build/app/outputs/flutter-apk/app-debug.apk

echo "✅ Done! The app is now installed with release signature."
echo "⚠️  Remember: License testing must still be configured in Play Console"
echo "⏰ Wait 15-30 minutes after adding license testers"