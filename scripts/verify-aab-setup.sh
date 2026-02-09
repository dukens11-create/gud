#!/bin/bash

# GitHub Actions AAB Setup Verification Script
# This script checks if all prerequisites are met for the GitHub Actions AAB build workflow

echo "🔍 GitHub Actions AAB Setup Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}❌ $1${NC}"
    ERRORS=$((ERRORS + 1))
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

echo "1️⃣ Checking Flutter Installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1)
    print_success "Flutter installed: $FLUTTER_VERSION"
else
    print_error "Flutter is not installed or not in PATH"
fi

echo ""
echo "2️⃣ Checking Java Installation..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    print_success "Java installed: $JAVA_VERSION"
else
    print_error "Java is not installed or not in PATH"
fi

echo ""
echo "3️⃣ Checking Workflow File..."
if [ -f ".github/workflows/build-aab.yml" ]; then
    print_success "Workflow file exists: .github/workflows/build-aab.yml"
else
    print_error "Workflow file not found: .github/workflows/build-aab.yml"
fi

echo ""
echo "4️⃣ Checking Android Build Configuration..."
if [ -f "android/app/build.gradle" ]; then
    if grep -q "signingConfigs" android/app/build.gradle; then
        print_success "Signing configuration found in build.gradle"
    else
        print_error "Signing configuration missing in build.gradle"
    fi
else
    print_error "build.gradle not found"
fi

echo ""
echo "5️⃣ Checking .gitignore Configuration..."
if [ -f ".gitignore" ]; then
    if grep -q "*.jks" .gitignore && grep -q "key.properties" .gitignore; then
        print_success ".gitignore properly configured for keystore files"
    else
        print_warning ".gitignore may not exclude all sensitive files"
    fi
else
    print_warning ".gitignore not found"
fi

echo ""
echo "6️⃣ Checking for Sensitive Files (should NOT exist in repo)..."
SENSITIVE_FILES_FOUND=0

if [ -f "android/app/gud_keystore.jks" ]; then
    print_error "Keystore file found in repository! Remove it immediately!"
    SENSITIVE_FILES_FOUND=$((SENSITIVE_FILES_FOUND + 1))
fi

if [ -f "android/key.properties" ]; then
    print_error "key.properties found in repository! Remove it immediately!"
    SENSITIVE_FILES_FOUND=$((SENSITIVE_FILES_FOUND + 1))
fi

if [ -f "keystore_base64.txt" ]; then
    print_error "keystore_base64.txt found! Remove it after adding to GitHub Secrets!"
    SENSITIVE_FILES_FOUND=$((SENSITIVE_FILES_FOUND + 1))
fi

if [ $SENSITIVE_FILES_FOUND -eq 0 ]; then
    print_success "No sensitive files found in repository"
fi

echo ""
echo "7️⃣ Checking Flutter Dependencies..."
if [ -f "pubspec.yaml" ]; then
    print_success "pubspec.yaml found"
    if [ -f "pubspec.lock" ]; then
        print_success "Dependencies are locked (pubspec.lock exists)"
    else
        print_warning "pubspec.lock not found. Run 'flutter pub get'"
    fi
else
    print_error "pubspec.yaml not found"
fi

echo ""
echo "8️⃣ Checking Documentation..."
if [ -f "GITHUB_ACTIONS_AAB_GUIDE.md" ]; then
    print_success "GitHub Actions guide found"
else
    print_warning "GitHub Actions guide not found"
fi

if [ -f "AAB_QUICK_START_GITHUB_ACTIONS.md" ]; then
    print_success "Quick start guide found"
else
    print_warning "Quick start guide not found"
fi

echo ""
echo "=========================================="
echo "📊 Verification Summary"
echo "=========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Your setup is ready for GitHub Actions AAB builds.${NC}"
    echo ""
    echo "📝 Next Steps:"
    echo "1. Generate a keystore (if you haven't already)"
    echo "2. Encode keystore to base64"
    echo "3. Add secrets to GitHub (KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS)"
    echo "4. Trigger the workflow from Actions tab"
    echo ""
    echo "📚 See GITHUB_ACTIONS_AAB_GUIDE.md for detailed instructions"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Setup complete with $WARNINGS warning(s)${NC}"
    echo "Review the warnings above and address them if needed."
    exit 0
else
    echo -e "${RED}❌ Setup incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo "Please address the errors above before proceeding."
    exit 1
fi
