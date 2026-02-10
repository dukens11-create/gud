#!/bin/bash
# ==============================================================================
# GUD Express - Android Keystore Generation Script
# ==============================================================================
# This script generates an Android keystore for signing release builds
# Generated keystore must be uploaded to Codemagic with reference name: gud-release-key
# ==============================================================================

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 GUD Express - Android Keystore Generator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configuration
KEYSTORE_FILE="gud-release-key.jks"
KEY_ALIAS="gud_key"
KEY_SIZE=2048
VALIDITY=10000  # ~27 years

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found!"
    echo ""
    echo "keytool is part of the Java Development Kit (JDK)."
    echo "Please install JDK and try again."
    echo ""
    echo "Installation instructions:"
    echo "  - Ubuntu/Debian: sudo apt-get install openjdk-11-jdk"
    echo "  - macOS: brew install openjdk@11"
    echo "  - Windows: Download from https://adoptium.net/"
    exit 1
fi

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Warning: Keystore file already exists: $KEYSTORE_FILE"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted. Existing keystore preserved."
        exit 0
    fi
    echo "🗑️  Removing existing keystore..."
    rm "$KEYSTORE_FILE"
fi

echo "📝 You will be prompted for the following information:"
echo "   1. Keystore password (IMPORTANT: Save this securely!)"
echo "   2. Key password (Can be same as keystore password)"
echo "   3. Your name"
echo "   4. Organization name (e.g., GUD Express)"
echo "   5. Organization unit (e.g., Development)"
echo "   6. City/Locality"
echo "   7. State/Province"
echo "   8. Country code (2 letters, e.g., US)"
echo ""
echo "⚠️  IMPORTANT: Remember all passwords! You cannot recover them if lost."
echo ""
read -p "Press Enter to continue..."
echo ""

# Generate keystore
echo "🔧 Generating keystore..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

keytool -genkey -v -keystore "$KEYSTORE_FILE" \
  -keyalg RSA \
  -keysize $KEY_SIZE \
  -validity $VALIDITY \
  -alias "$KEY_ALIAS"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Keystore generated successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Keystore file: $KEYSTORE_FILE"
echo "🔑 Key alias: $KEY_ALIAS"
echo "🔐 Key algorithm: RSA $KEY_SIZE"
echo "📅 Valid for: $VALIDITY days (~27 years)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  IMPORTANT: Save Your Credentials!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Save the following in a secure password manager:"
echo ""
echo "  1. Keystore password: _______________________________"
echo "  2. Key password: _____________________________________"
echo "  3. Key alias: $KEY_ALIAS"
echo "  4. Keystore file location: $(pwd)/$KEYSTORE_FILE"
echo ""
echo "⚠️  WARNING: If you lose these credentials, you CANNOT:"
echo "   - Update your app on Google Play Store"
echo "   - Generate new releases with the same signature"
echo "   - Recover the keystore"
echo ""
echo "💾 Backup: Store the keystore file ($KEYSTORE_FILE) in a secure location!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📤 Next Steps: Upload to Codemagic"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Login to Codemagic: https://codemagic.io/"
echo "2. Open your 'gud' app"
echo "3. Go to: Settings → Code signing identities → Android"
echo "4. Click 'Add keystore'"
echo "5. Upload with these details:"
echo "   - Keystore file: $KEYSTORE_FILE"
echo "   - Reference name: gud-release-key  ⚠️ MUST BE EXACTLY THIS"
echo "   - Key alias: $KEY_ALIAS"
echo "   - Passwords: (the ones you just entered)"
echo ""
echo "📚 Detailed guide: See CODEMAGIC_KEYSTORE_SETUP.md"
echo "📋 Quick checklist: See QUICK_FIX_CHECKLIST.md"
echo ""
echo "✅ Setup complete! Follow the upload instructions above."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
