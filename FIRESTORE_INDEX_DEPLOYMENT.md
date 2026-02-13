# Firestore Index Deployment Guide

This guide provides step-by-step instructions for deploying Firestore indexes to fix the Document Verification page error.

## Problem

The Document Verification page displays this error:

```
Error: [cloud_firestore/failed-precondition] The query requires a COLLECTION_GROUP_ASC index for collection documents and field status.
```

This occurs because the Document Verification screen queries the `documents` subcollection across all drivers using a collection group query, but the required composite indexes don't exist in Firestore.

## Solution: Deploy Firestore Indexes

### Prerequisites

Before deploying indexes, ensure you have:

1. **Firebase CLI installed**:
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase authentication**:
   ```bash
   firebase login
   ```

3. **Appropriate Firebase project permissions**:
   - You must be an Owner or Editor on the Firebase project
   - Check your access at: https://console.firebase.google.com/project/YOUR_PROJECT/settings/iam

### Deployment Steps

#### Option 1: Using the Deployment Script (Recommended)

The fastest and most reliable method:

```bash
# From the project root directory
./scripts/deploy-firestore-indexes.sh
```

**What this does:**
- ✅ Validates Firebase CLI installation
- ✅ Checks Firebase authentication
- ✅ Deploys all indexes from `firestore.indexes.json`
- ✅ Provides clear status messages

**Time:** 2-10 minutes depending on database size

#### Option 2: Using Firebase CLI Directly

If the script is not available or you prefer manual deployment:

```bash
# From the project root directory
firebase deploy --only firestore:indexes
```

**Expected output:**
```
=== Deploying to 'your-project-id'...

i  deploying firestore
i  firestore: checking firestore.indexes.json for compilation errors...
✔  firestore: compiled firestore.indexes.json successfully
i  firestore: uploading indexes firestore.indexes.json...
✔  firestore: deployed indexes in firestore.indexes.json successfully

✔  Deploy complete!
```

### Verifying Index Deployment

#### 1. Check Firebase Console

After deployment, verify the indexes are building:

1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project (e.g., `gud-express`)
3. Navigate to: **Firestore Database** → **Indexes** tab
4. Look for the new indexes for the `documents` collection group:
   - **Index 1**: `status` (Ascending)
   - **Index 2**: `status` (Ascending) + `uploadedAt` (Descending)

#### 2. Monitor Index Build Status

Index build times vary based on database size:

| Database Size | Typical Build Time |
|---------------|-------------------|
| Empty/Small | 1-2 minutes |
| Medium | 2-5 minutes |
| Large | 10-30 minutes |
| Very Large | 30+ minutes |

**Status indicators:**
- 🔵 **Building**: Index is being created (wait for completion)
- ✅ **Enabled**: Index is ready to use
- ❌ **Error**: Index creation failed (see troubleshooting)

#### 3. Test Document Verification Page

Once indexes show "Enabled" status:

1. Open the GUD Express app
2. Navigate to: **Admin Panel** → **Document Verification**
3. Verify the page loads without errors
4. Confirm you can see pending driver documents

### Direct Firebase Console Link

For quick access to your project's indexes:

```
https://console.firebase.google.com/project/gud-express/firestore/indexes
```

*(Replace `gud-express` with your actual project ID)*

## Troubleshooting

### Issue: "Permission Denied" Error

**Symptom:**
```
Error: HTTP Error: 403, The caller does not have permission
```

**Solution:**
- Verify you're logged in: `firebase login`
- Check you have Owner/Editor role on the Firebase project
- Contact project administrator to grant appropriate permissions

### Issue: "Project Not Found"

**Symptom:**
```
Error: Failed to get Firebase project gud-express. Please make sure the project exists and your account has permission to access it.
```

**Solution:**
1. Verify project ID in `firebase.json` and `.firebaserc` files
2. List your projects: `firebase projects:list`
3. Select the correct project: `firebase use PROJECT_ID`

### Issue: Index Build Takes Too Long

**Symptom:** Index status stays at "Building" for more than 30 minutes

**Solutions:**
- **Wait longer**: Very large databases can take hours
- **Check Firebase status**: https://status.firebase.google.com
- **Contact Firebase support**: If build exceeds several hours

### Issue: Index Build Fails (Error Status)

**Symptom:** Index status shows "Error" or "Failed"

**Solutions:**

1. **Delete the failed index:**
   - Go to Firebase Console → Firestore → Indexes
   - Click the **trash icon** next to the failed index
   - Wait for deletion to complete

2. **Redeploy:**
   ```bash
   firebase deploy --only firestore:indexes
   ```

3. **Check for data issues:**
   - Verify field names match exactly (case-sensitive)
   - Check for documents with missing or incorrect field types
   - Ensure `status` field is a string, not an array or object

### Issue: Query Still Fails After Index Creation

**Symptom:** Document Verification page still shows error after index is "Enabled"

**Possible Causes & Solutions:**

1. **App cache issue:**
   - Close and restart the app completely
   - Clear app cache (on device: Settings → Apps → GUD Express → Clear Cache)

2. **Wrong query:**
   - Verify the query matches the index configuration
   - Check code in `lib/services/driver_extended_service.dart`

3. **Field name mismatch:**
   - Ensure fields are named exactly: `status` and `uploadedAt`
   - Fields are case-sensitive

4. **Multiple queries:**
   - If you have multiple queries, ensure indexes exist for all of them
   - Check app logs for any additional index errors

### Issue: Index Already Exists

**Symptom:**
```
Error: Index already exists
```

**Solution:**
- The index has already been deployed
- Check Firebase Console to verify it's enabled
- If status is "Building", wait for it to complete
- If you need to update it, delete the old index first

## Alternative: Create Index from Error Link

If you see the Firestore error in the app, you can use the automatic index creation:

1. **Copy the URL from the error message:**
   ```
   The query requires an index. You can create it here:
   https://console.firebase.google.com/project/gud-express/firestore/indexes?create_composite=...
   ```

2. **Open the link in your browser:**
   - The Firebase Console will open with the index pre-configured

3. **⚠️ IMPORTANT: Check for `__name__` field:**
   - Firebase Console sometimes auto-adds a `__name__` field
   - This extra field causes queries to fail
   - **Remove the `__name__` field** if present (click the X button)

4. **Click "Create Index":**
   - Wait 2-5 minutes for the index to build
   - Refresh the Document Verification page

**Note:** Using the deployment script (Option 1) is preferred as it avoids the `__name__` field issue.

## Required Indexes

The `firestore.indexes.json` file contains these indexes for the Document Verification feature:

### Index 1: Basic Status Query
```json
{
  "collectionGroup": "documents",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    }
  ]
}
```

**Used by:**
- Query: `collectionGroup('documents').where('status', isEqualTo: 'pending')`
- Purpose: Retrieve all pending documents across all drivers

### Index 2: Status with Upload Date Sorting
```json
{
  "collectionGroup": "documents",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "uploadedAt",
      "order": "DESCENDING"
    }
  ]
}
```

**Used by:**
- Query: `collectionGroup('documents').where('status', isEqualTo: 'pending').orderBy('uploadedAt', descending: true)`
- Purpose: Retrieve pending documents sorted by upload date (newest first)

## Post-Deployment Verification

After deployment and index build completion, verify the following:

- ✅ Document Verification page loads without errors
- ✅ Pending driver documents are displayed
- ✅ Documents can be filtered by status (pending/valid/rejected)
- ✅ Documents are sorted correctly by upload date
- ✅ No Firestore index errors in console logs

## Maintenance

### When to Redeploy Indexes

Redeploy indexes when:
- Adding new query patterns that require composite indexes
- Modifying existing queries (adding fields, changing sort order)
- Getting "Index Required" errors in production
- After updating `firestore.indexes.json`

### Best Practices

1. **Test queries locally** before deploying to production
2. **Deploy indexes proactively** before releasing features that need them
3. **Monitor index status** regularly in Firebase Console
4. **Document all queries** that require composite indexes
5. **Use version control** for `firestore.indexes.json` to track changes

## Additional Resources

- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md) - Comprehensive index guide
- [FIRESTORE_INDEX_TROUBLESHOOTING.md](FIRESTORE_INDEX_TROUBLESHOOTING.md) - Detailed troubleshooting

## Support

If you encounter issues not covered in this guide:

1. Check [FIRESTORE_INDEX_TROUBLESHOOTING.md](FIRESTORE_INDEX_TROUBLESHOOTING.md)
2. Review Firebase Console for index status and errors
3. Check app debug logs for specific error messages
4. Verify your Firebase project permissions
5. Contact the development team with:
   - Error message screenshot
   - Firebase Console index status
   - Firebase project ID
   - Steps to reproduce the issue
