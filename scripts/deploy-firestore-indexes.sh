#!/bin/bash

# GUD Express Firestore Index Deployment Script
# This script deploys Firestore composite indexes from firestore.indexes.json

set -e

echo "=========================================="
echo "GUD Express Firestore Index Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Firebase CLI is installed
echo -e "${YELLOW}Step 1/4: Checking Firebase CLI installation...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}ERROR: Firebase CLI is not installed!${NC}"
    echo ""
    echo "Please install Firebase CLI first:"
    echo "  npm install -g firebase-tools"
    echo ""
    echo "Or visit: https://firebase.google.com/docs/cli"
    exit 1
fi

FIREBASE_VERSION=$(firebase --version)
echo -e "${GREEN}✓ Firebase CLI is installed (version: $FIREBASE_VERSION)${NC}"
echo ""

# Check if firestore.indexes.json exists
echo -e "${YELLOW}Step 2/4: Validating firestore.indexes.json...${NC}"
if [ ! -f "firestore.indexes.json" ]; then
    echo -e "${RED}ERROR: firestore.indexes.json not found!${NC}"
    echo ""
    echo "Please run this script from the project root directory."
    exit 1
fi

# Count indexes in file
INDEX_COUNT=$(grep -o '"collectionGroup"' firestore.indexes.json | wc -l | tr -d ' ')
echo -e "${GREEN}✓ Found firestore.indexes.json with $INDEX_COUNT indexes${NC}"
echo ""

# Check Firebase authentication
echo -e "${YELLOW}Step 3/4: Checking Firebase authentication...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠ Not logged in to Firebase${NC}"
    echo ""
    echo "Running: firebase login"
    firebase login
    echo ""
fi
echo -e "${GREEN}✓ Firebase authentication verified${NC}"
echo ""

# Deploy indexes
echo -e "${YELLOW}Step 4/4: Deploying Firestore indexes...${NC}"
echo ""
echo "This will deploy all indexes defined in firestore.indexes.json to your Firebase project."
echo "Deployment typically takes 2-5 minutes for small databases."
echo "Large databases may take 10-30+ minutes."
echo ""

firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "✓ Firestore indexes deployed successfully!"
    echo "==========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Go to Firebase Console → Firestore Database → Indexes"
    echo "2. Wait for index status to change from 'Building' to 'Enabled'"
    echo "3. Test your app queries"
    echo ""
    echo "For troubleshooting, see: FIRESTORE_INDEX_TROUBLESHOOTING.md"
else
    echo ""
    echo -e "${RED}=========================================="
    echo "✗ Deployment failed!"
    echo "==========================================${NC}"
    echo ""
    echo "Common issues:"
    echo "1. Wrong Firebase project selected - run 'firebase use [project-id]'"
    echo "2. Missing permissions - ensure you have Owner/Editor role"
    echo "3. Invalid index configuration - check firestore.indexes.json syntax"
    echo ""
    echo "For more help, see: FIRESTORE_INDEX_TROUBLESHOOTING.md"
    exit 1
fi
