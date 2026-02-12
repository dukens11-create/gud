#!/bin/bash
# Deploy Firestore indexes to Firebase

echo "🔥 Deploying Firestore Indexes..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found!"
    echo "📦 Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
if ! firebase projects:list &> /dev/null; then
    echo "🔑 Please log in to Firebase..."
    firebase login
fi

# Deploy indexes
echo "📤 Deploying indexes from firestore.indexes.json..."
firebase deploy --only firestore:indexes

if [ $? -eq 0 ]; then
    echo "✅ Firestore indexes deployed successfully!"
    echo "⏱️  Indexes will be built in 2-5 minutes"
    echo "🔍 Check status: https://console.firebase.google.com/project/_/firestore/indexes"
else
    echo "❌ Deployment failed!"
    exit 1
fi
