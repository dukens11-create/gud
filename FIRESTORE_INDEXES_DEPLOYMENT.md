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
- Check status: https://console.firebase.google.com/project/gud-express/firestore/indexes

## Verify Indexes are Active
All indexes should show status: **Enabled** (green)

## Troubleshooting

### Error: "Index already exists"
- This is OK - indexes are already deployed

### Error: "Permission denied"
```bash
firebase login
firebase use gud-express
```

### Indexes show "Building..."
- Wait 2-5 minutes and refresh the page
- App errors will disappear once status is "Enabled"

## Manual Index Creation (Fallback)

If CLI deployment fails, click the error links in the app:
- Document Verification error → click link
- Maintenance Tracking error → click link  
- My Expenses error → click link
