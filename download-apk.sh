#!/bin/bash

# GUD Express APK Download Script
# This script helps you download the latest APK using GitHub CLI

set -e

echo "================================================"
echo "  GUD Express - APK Download Helper"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed!"
    echo ""
    echo "📦 Install it from: https://cli.github.com/"
    echo ""
    echo "Or download manually from:"
    echo "👉 https://github.com/dukens11-create/gud/actions/runs/21572746265"
    echo ""
    exit 1
fi

echo "✅ GitHub CLI found!"
echo ""

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub!"
    echo ""
    echo "Run: gh auth login"
    echo ""
    exit 1
fi

echo "✅ GitHub authentication verified!"
echo ""

# Download the APK
echo "📥 Downloading APK artifact..."
echo ""

RUN_ID="21572746265"
ARTIFACT_NAME="android-apk"
REPO="dukens11-create/gud"

gh run download "$RUN_ID" -n "$ARTIFACT_NAME" -R "$REPO"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "  ✅ Download Complete!"
    echo "================================================"
    echo ""
    echo "📱 APK Location: ./app-release.apk"
    echo ""
    echo "Next steps:"
    echo "  1. Transfer app-release.apk to your Android device"
    echo "  2. Enable 'Unknown Sources' in Settings"
    echo "  3. Tap the APK to install"
    echo ""
    echo "🎉 Enjoy GUD Express!"
    echo ""
else
    echo ""
    echo "❌ Download failed!"
    echo ""
    echo "Try downloading manually:"
    echo "👉 https://github.com/dukens11-create/gud/actions/runs/21572746265"
    echo ""
    exit 1
fi
