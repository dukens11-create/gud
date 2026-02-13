# Firestore Indexes Deployment Guide

## Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in: `firebase login`

## Deploy All Indexes at Once

```bash
# From project root directory
firebase deploy --only firestore:indexes
```

## Wait for Index Build
- Indexes take **2-5 minutes** to build
- Check status: https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/indexes

## Verify Indexes are Active
All indexes should show status: **Enabled** (green)

## Troubleshooting

### Error: "Index already exists"
- This is OK - indexes are already deployed

### Error: "Permission denied"
```bash
firebase login
# Replace YOUR_PROJECT_ID with your actual Firebase project ID
firebase use YOUR_PROJECT_ID

# To list available projects:
# firebase projects:list
```

### Indexes show "Building..."
- Wait 2-5 minutes and refresh the page
- App errors will disappear once status is "Enabled"

## Manual Index Creation (Fallback)

If CLI deployment fails, you can create indexes directly from error messages in the app:

1. **Run the app** and navigate to the screen showing the error
2. **Copy the error link** - error messages like `[cloud_firestore/failed-precondition]` include a Firebase Console URL
3. **Click or paste the link** into your browser - this will redirect to Firebase Console with the index pre-configured
4. **Click "Create Index"** button in Firebase Console
5. **Wait 2-5 minutes** for the index to build

Example error messages to look for:
- Document Verification error → click the console.firebase.google.com link in the error
- Maintenance Tracking error → click the console.firebase.google.com link in the error
- My Expenses error → click the console.firebase.google.com link in the error
