# Firestore Index Setup Guide

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

## How to Create Indexes

### Method 1: Automatic Creation from Error

1. Run the app and trigger the query that needs the index
2. Firestore will throw an error with a direct link to create the index
3. Click the link in the error message
4. Firebase Console will open with the index pre-configured
5. Click "Create Index" button
6. Wait 2-5 minutes for the index to build

**Example Error Message**:
```
The query requires an index. You can create it here: 
https://console.firebase.google.com/project/YOUR_PROJECT/firestore/indexes?create_composite=...
```

### Method 2: Manual Creation in Firebase Console

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
   - **Query scope**: `Collection`
6. Click **Create** button
7. Wait for index to build (status will change from "Building" to "Enabled")

### Method 3: Deploy from Configuration File

This project includes index definitions in `firestore.indexes.json`. Deploy them using:

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy only Firestore indexes
firebase deploy --only firestore:indexes
```

**Note**: This method requires Firebase CLI and proper project configuration.

## Troubleshooting

### Index Error in App

**Symptom**: App shows "Firestore Index Required" error when filtering loads

**Solution**:
1. Check the app logs (debug console) for the exact index URL
2. Click the URL or follow Method 2 above
3. Create the missing index
4. Wait for index to build
5. Tap "Retry" in the app

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
