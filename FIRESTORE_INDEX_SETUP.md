# Firestore Index Setup Guide

## ⚠️ CRITICAL: Avoid the `__name__` Field Issue

**Before creating indexes manually in Firebase Console:**

When you create a Firestore composite index through the Firebase Console UI, it **automatically adds a `__name__` field** to your index. This extra field causes queries to fail in the app.

**❌ DO NOT** create indexes with the `__name__` field  
**✅ USE** the deployment script (recommended) or manually remove `__name__` before creating

👉 **See [FIRESTORE_INDEX_TROUBLESHOOTING.md](FIRESTORE_INDEX_TROUBLESHOOTING.md) for detailed troubleshooting**

---

## Quick Fix: Deploy All Indexes Automatically

**Fastest and safest method to set up all required indexes:**

```bash
# Run from project root directory
./scripts/deploy-firestore-indexes.sh
```

This script will:
- ✅ Check Firebase CLI installation
- ✅ Validate configuration files
- ✅ Deploy all indexes correctly (without `__name__` field)
- ✅ Provide clear status messages

**Time:** 2-10 minutes depending on database size

**Requirements:**
- Firebase CLI: `npm install -g firebase-tools`
- Firebase authentication: `firebase login`

---

## Overview

This application uses Firestore composite indexes to efficiently query loads by multiple fields. This guide explains how to create and maintain these indexes.

## Required Indexes

### 1. Driver Loads with Status Filter

**Purpose**: Filter loads by driver and status, ordered by creation date

**Index Configuration**:
- Collection: `loads`
- Fields (in order):
  1. `driverId` (Ascending)
  2. `status` (Ascending)
  3. `createdAt` (Descending)

**Used by**: 
- Driver Home Screen - Status filter tabs (All, Assigned, In Transit, Delivered)
- Query: `FirebaseFirestore.instance.collection('loads').where('driverId', isEqualTo: driverId).where('status', isEqualTo: status).orderBy('createdAt', descending: true)`

### 2. Driver Loads (All Statuses)

**Purpose**: Get all loads for a driver, ordered by creation date

**Index Configuration**:
- Collection: `loads`
- Fields (in order):
  1. `driverId` (Ascending)
  2. `createdAt` (Descending)

**Used by**: 
- Driver Home Screen - "All" status tab
- Query: `FirebaseFirestore.instance.collection('loads').where('driverId', isEqualTo: driverId).orderBy('createdAt', descending: true)`

### 3. Document Verification (Collection Group)

**Purpose**: Get all pending documents across all drivers for admin verification

**Index Configuration**:
- Collection Group: `documents`
- Query Scope: `COLLECTION_GROUP`
- Fields (in order):
  1. `status` (Ascending)

**Used by**: 
- Admin Document Verification Screen
- Query: `FirebaseFirestore.instance.collectionGroup('documents').where('status', isEqualTo: 'pending')`

**Note**: This is a **collection group query** that searches across all subcollections named `documents` (e.g., `/drivers/{driverId}/documents/{docId}`). Collection group queries require `queryScope: "COLLECTION_GROUP"` in the index configuration.

## How to Create Indexes

### ⭐ Method 1: Use the Deployment Script (Recommended)

**This is the fastest and most reliable method.**

```bash
# Run from project root directory
./scripts/deploy-firestore-indexes.sh
```

**Advantages:**
- ✅ Deploys all indexes correctly from `firestore.indexes.json`
- ✅ No manual configuration needed
- ✅ Prevents the `__name__` field issue automatically
- ✅ Version controlled and reproducible
- ✅ Works for all team members

**Steps:**
1. Install Firebase CLI (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Run the deployment script:
   ```bash
   ./scripts/deploy-firestore-indexes.sh
   ```

4. Wait for indexes to build (typically 2-10 minutes)

5. Verify in Firebase Console → Firestore → Indexes tab

**Time:** 2-10 minutes depending on database size

---

### Method 2: Automatic Creation from Error

⚠️ **Warning:** This method may auto-include the `__name__` field. Use Method 1 (deployment script) if possible.

1. Run the app and trigger the query that needs the index
2. Firestore will throw an error with a direct link to create the index
3. Click the link in the error message
4. Firebase Console will open with the index pre-configured
5. **IMPORTANT:** Check if a `__name__` field was auto-added
   - If present, either:
     - Remove it before creating (click the X next to the field)
     - OR use Method 1 (deployment script) instead
6. Click "Create Index" button
7. Wait 2-5 minutes for the index to build

**Example Error Message**:
```
The query requires an index. You can create it here: 
https://console.firebase.google.com/project/YOUR_PROJECT/firestore/indexes?create_composite=...
```

---

### Method 3: Manual Creation in Firebase Console

⚠️ **Warning:** Firebase Console auto-adds a `__name__` field. You must manually remove it.

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes** tab
4. Click **Create Index** button
5. Configure the index:
   - **Collection ID**: `loads`
   - **Fields to index**:
     - Add field: `driverId`, Order: `Ascending`
     - Add field: `status`, Order: `Ascending`
     - Add field: `createdAt`, Order: `Descending`
   - ⚠️ **REMOVE the `__name__` field if it appears** (click the X button)
   - **Query scope**: `Collection`
6. Click **Create** button
7. Wait for index to build (status will change from "Building" to "Enabled")

**Important Notes:**
- Firebase Console automatically adds a `__name__` field to composite indexes
- This field causes queries to fail in the app
- Always verify and remove the `__name__` field before creating the index
- If you forget to remove it, see [FIRESTORE_INDEX_TROUBLESHOOTING.md](FIRESTORE_INDEX_TROUBLESHOOTING.md) for how to fix it

---

### Method 4: Deploy from Configuration File (Advanced)

This method is similar to Method 1 but uses Firebase CLI commands directly.

This project includes index definitions in `firestore.indexes.json`. Deploy them using:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy only Firestore indexes
firebase deploy --only firestore:indexes
```

**Note**: This method requires Firebase CLI and proper project configuration. The deployment script (Method 1) wraps these commands with helpful checks and messages.

## Troubleshooting

### 📖 Comprehensive Troubleshooting Guide

For detailed troubleshooting, including the `__name__` field issue, see:
👉 **[FIRESTORE_INDEX_TROUBLESHOOTING.md](FIRESTORE_INDEX_TROUBLESHOOTING.md)**

### Quick Troubleshooting

### Index Error in App

**Symptom**: App shows "Firestore Index Required" error when filtering loads

**Quick Solutions**:
1. **Use the deployment script** (fastest):
   ```bash
   ./scripts/deploy-firestore-indexes.sh
   ```
2. Check the app logs for the index creation URL
3. Click the URL, but verify no `__name__` field was added
4. Wait for index to build
5. Retry the query

👉 **Detailed steps:** [FIRESTORE_INDEX_TROUBLESHOOTING.md#common-issue-__name__-field-problem](FIRESTORE_INDEX_TROUBLESHOOTING.md#common-issue-__name__-field-problem)

### Index Build Time

- **Typical**: 2-5 minutes for small databases
- **Large databases**: Can take 10-30+ minutes
- **Status**: Check Firebase Console → Firestore → Indexes tab

### Index Already Exists Error

**Symptom**: "Index already exists" when trying to create

**Solution**:
- The index is already created and may still be building
- Check the Indexes tab for status
- If status is "Error", delete and recreate the index
- If index has `__name__` field, delete it and use the deployment script

👉 **Detailed steps:** [FIRESTORE_INDEX_TROUBLESHOOTING.md#deleting-incorrect-indexes](FIRESTORE_INDEX_TROUBLESHOOTING.md#deleting-incorrect-indexes)

### Query Still Failing After Index Creation

**Possible Causes**:
1. Index is still building (check status in console)
2. Field names don't match exactly (case-sensitive)
3. Field types don't match (string vs number)
4. Query order doesn't match index configuration

**Solution**:
- Wait a few more minutes
- Verify field names in both query and index
- Check index status in Firebase Console
- Review error message for specific issues

## Index Maintenance

### When to Update Indexes

Update indexes when:
- Adding new query patterns
- Changing sort orders in queries
- Adding new where clauses to existing queries
- Getting index errors in production

### Index Management Best Practices

1. **Always test queries** in development before deploying to production
2. **Create indexes proactively** before releasing features that need them
3. **Monitor index usage** in Firebase Console to identify unused indexes
4. **Document all queries** that require composite indexes
5. **Use `firestore.indexes.json`** to track and version control indexes

## Query Examples

### Get All Loads for a Driver (Any Status)

```dart
FirebaseFirestore.instance
  .collection('loads')
  .where('driverId', isEqualTo: driverId)
  .orderBy('createdAt', descending: true)
  .snapshots();
```

**Required Index**: `driverId` (Asc) + `createdAt` (Desc)

### Get Loads for a Driver by Status

```dart
FirebaseFirestore.instance
  .collection('loads')
  .where('driverId', isEqualTo: driverId)
  .where('status', isEqualTo: 'assigned')  // or 'in_transit', 'delivered'
  .orderBy('createdAt', descending: true)
  .snapshots();
```

**Required Index**: `driverId` (Asc) + `status` (Asc) + `createdAt` (Desc)

### Get Active Trucks (Excluding Inactive)

```dart
FirebaseFirestore.instance
  .collection('trucks')
  .where('status', whereIn: ['available', 'in_use', 'maintenance'])
  .orderBy('truckNumber')
  .snapshots();
```

**Required Index**: `status` (Asc) + `truckNumber` (Asc)

**Note**: This query uses `whereIn` instead of `isNotEqualTo: 'inactive'` because:
- Inequality operators (`!=`, `<`, `>`) require the inequality field to be first in the index
- This would conflict with sorting by `truckNumber`
- Using `whereIn` with explicit status values works with standard composite indexes

### Get Pending Documents Across All Drivers (Collection Group Query)

```dart
FirebaseFirestore.instance
  .collectionGroup('documents')
  .where('status', isEqualTo: 'pending')
  .snapshots();
```

**Required Index**: `status` (Asc) with `queryScope: "COLLECTION_GROUP"`

**Note**: Collection group queries search across all subcollections with the same name (e.g., all `documents` subcollections under different driver documents). These require special indexes with `queryScope: "COLLECTION_GROUP"` instead of `queryScope: "COLLECTION"`.

## Additional Resources

- [Firestore Index Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Composite Index Best Practices](https://firebase.google.com/docs/firestore/query-data/index-overview)
- [Firebase Console](https://console.firebase.google.com)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)

## Support

If you encounter issues with indexes:
1. Check this guide first
2. Review app debug logs for specific error messages
3. Check Firebase Console for index status
4. Refer to Firebase documentation
5. Contact the development team with error details
