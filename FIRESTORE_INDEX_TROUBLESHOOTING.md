# Firestore Index Troubleshooting Guide

## Quick Navigation
- [Common Issue: `__name__` Field Problem](#common-issue-__name__-field-problem)
- [Deleting Incorrect Indexes](#deleting-incorrect-indexes)
- [Creating the Correct Index](#creating-the-correct-index)
- [Verifying Index is Correct](#verifying-index-is-correct)
- [Other Common Issues](#other-common-issues)

---

## Common Issue: `__name__` Field Problem

### The Problem

When you manually create a Firestore composite index in the Firebase Console, it **automatically adds a `__name__` field** to your index. This extra field causes queries to fail because it doesn't match the actual query pattern used in the app.

### ⚠️ Why This Happens

Firebase Console automatically adds `__name__` as the last field in composite indexes by default. While this is sometimes useful for pagination, it breaks queries that don't include this field in their sorting logic.

### ❌ Incorrect Index (with `__name__`)

```json
{
  "collectionGroup": "loads",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "driverId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    },
    {
      "fieldPath": "__name__",  ← THIS SHOULD NOT BE HERE!
      "order": "ASCENDING"
    }
  ]
}
```

### ✅ Correct Index (without `__name__`)

```json
{
  "collectionGroup": "loads",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "driverId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

---

## Deleting Incorrect Indexes

If you've already created an index with the `__name__` field, you need to delete it before creating the correct one.

### Step-by-Step Instructions

1. **Go to Firebase Console**
   - Open [Firebase Console](https://console.firebase.google.com)
   - Select your project (e.g., "GUD Express")

2. **Navigate to Indexes**
   - Click **Firestore Database** in the left sidebar
   - Click the **Indexes** tab at the top

3. **Find the Incorrect Index**
   - Look for an index on the `loads` collection
   - Check if it has these fields: `driverId`, `status`, `createdAt`, **and `__name__`**
   - Note: The index may show "Building" or "Enabled" status

4. **Delete the Index**
   - Click the **⋮** (three dots) menu on the right side of the index row
   - Select **Delete**
   - Confirm the deletion in the popup dialog

5. **Wait for Deletion**
   - The index will disappear from the list
   - This is instant, no waiting required

---

## Creating the Correct Index

After deleting the incorrect index, you have three options to create the correct one:

### ✅ Option 1: Use the Deployment Script (Recommended)

**Fastest and most reliable method:**

```bash
# Run from project root
./scripts/deploy-firestore-indexes.sh
```

**Benefits:**
- ✅ Deploys all indexes correctly from `firestore.indexes.json`
- ✅ No manual configuration needed
- ✅ Prevents the `__name__` field issue
- ✅ Version controlled and reproducible

**Requirements:**
- Firebase CLI installed (`npm install -g firebase-tools`)
- Logged in to Firebase (`firebase login`)

**Time:** 2-10 minutes depending on database size

---

### Option 2: Use the Error Link

**Good for quick fixes:**

1. Run your app and trigger the query that needs the index
2. Look for an error message like:
   ```
   The query requires an index. You can create it here: 
   https://console.firebase.google.com/project/YOUR_PROJECT/firestore/indexes?create_composite=...
   ```
3. Copy the full URL from the error
4. Open it in your browser
5. **IMPORTANT:** Before clicking "Create Index", verify:
   - ✅ Collection ID: `loads`
   - ✅ Fields: `driverId`, `status`, `createdAt`
   - ❌ **NO `__name__` field** - if you see it, **DO NOT** create this index
6. If `__name__` is present:
   - Close the browser tab
   - Use Option 1 (deployment script) instead
7. If `__name__` is NOT present:
   - Click **Create Index**
   - Wait 2-10 minutes for it to build

**Note:** This method sometimes includes the `__name__` field, which is why the deployment script (Option 1) is recommended.

---

### Option 3: Manual Creation (Advanced)

**Use this if the deployment script fails:**

1. **Open Firebase Console**
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project

2. **Navigate to Indexes**
   - Click **Firestore Database** → **Indexes** tab
   - Click **Create Index** button

3. **Configure Collection Settings**
   - **Collection ID:** `loads`
   - **Query scope:** `Collection`

4. **Add Fields (Order Matters!)**
   
   Click **Add field** and configure each field in this exact order:
   
   | Field | Index Type |
   |-------|-----------|
   | `driverId` | Ascending |
   | `status` | Ascending |
   | `createdAt` | Descending |

5. **⚠️ CRITICAL: Remove `__name__` Field**
   
   - If you see a `__name__` field at the bottom, click the **X** to remove it
   - This field is auto-added by Firebase but should NOT be included

6. **Create the Index**
   - Double-check: Only 3 fields (`driverId`, `status`, `createdAt`)
   - Click **Create** button
   - Wait 2-10 minutes for index to build

---

## Verifying Index is Correct

### Visual Check in Firebase Console

1. Go to **Firestore Database** → **Indexes** tab
2. Find your `loads` index
3. Verify it shows:
   ```
   Collection ID: loads
   Fields indexed: 
     driverId Ascending
     status Ascending  
     createdAt Descending
   ```
4. **IMPORTANT:** Ensure there's NO `__name__` field listed
5. Wait for status to change from **Building** → **Enabled**

### Test in Your App

1. Open the GUD Express app
2. Log in as a driver
3. Navigate to "My Loads" screen
4. Try switching between status tabs:
   - All
   - Assigned
   - In Transit
   - Delivered
5. If loads appear without errors, the index is working correctly

### Check Via Firebase CLI

```bash
# List all indexes
firebase firestore:indexes

# Look for the loads index in the output
# Verify it has only 3 fields (no __name__)
```

---

## Other Common Issues

### Issue: "Index Already Exists" Error

**Symptom:** Can't create index because it already exists

**Solutions:**
1. Check Indexes tab - the index may be building already
2. Wait 5-10 minutes for existing index to finish building
3. If status shows "Error", delete and recreate
4. Check for duplicate indexes with slightly different configurations

---

### Issue: Query Still Fails After Creating Index

**Symptom:** App still shows "Index required" error after creating index

**Possible Causes & Solutions:**

1. **Index is still building**
   - Solution: Wait longer (check status in Firebase Console)
   - Large databases can take 10-30+ minutes

2. **Wrong index configuration**
   - Solution: Verify field names match exactly (case-sensitive)
   - Solution: Verify field order matches query order
   - Solution: Check for `__name__` field and remove it

3. **Cached error in app**
   - Solution: Restart the app completely
   - Solution: Clear app cache
   - Solution: Try on a different device

4. **Multiple indexes needed**
   - Solution: The app may need multiple indexes
   - Solution: Use the deployment script to deploy all indexes at once

---

### Issue: Deployment Script Fails

**Symptom:** `./scripts/deploy-firestore-indexes.sh` returns errors

**Common Causes & Solutions:**

1. **"Firebase CLI not installed"**
   ```bash
   npm install -g firebase-tools
   ```

2. **"Not logged in to Firebase"**
   ```bash
   firebase login
   ```

3. **"Wrong project"**
   ```bash
   # List available projects
   firebase projects:list
   
   # Select the correct project
   firebase use [project-id]
   ```

4. **"Missing permissions"**
   - Ensure your Firebase account has Owner or Editor role
   - Contact project admin to grant permissions

5. **"firestore.indexes.json not found"**
   - Run the script from the project root directory:
     ```bash
     cd /path/to/gud
     ./scripts/deploy-firestore-indexes.sh
     ```

---

### Issue: Index Takes Too Long to Build

**Symptom:** Index status stuck on "Building" for 30+ minutes

**What to Check:**

1. **Database size**
   - Large databases (10,000+ documents) can take 1-2 hours
   - Check document count: Firebase Console → Firestore → Data tab

2. **Firebase service status**
   - Check [Firebase Status Dashboard](https://status.firebase.google.com)
   - Look for Firestore incidents

3. **Multiple indexes building simultaneously**
   - If deploying many indexes at once, they build sequentially
   - Each index must complete before the next starts

**Solutions:**
- Be patient - Firestore is processing your data
- Don't delete and recreate - this restarts the process
- If stuck for 2+ hours, contact Firebase support

---

### Issue: Different Error Than Expected

**Symptom:** Error message doesn't mention indexes

**Common alternative errors:**

1. **"Insufficient permissions"**
   - Check Firestore security rules
   - See [FIRESTORE_RULES.md](FIRESTORE_RULES.md)

2. **"Collection not found"**
   - Verify collection name is spelled correctly
   - Check if data exists in Firestore

3. **"Invalid query"**
   - Check query syntax in code
   - Verify field names match Firestore document structure

---

## Quick Reference: Command Cheatsheet

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy all indexes (recommended)
./scripts/deploy-firestore-indexes.sh

# List current indexes
firebase firestore:indexes

# Select Firebase project
firebase use [project-id]

# List available projects
firebase projects:list
```

---

## Getting Help

If you're still experiencing issues:

1. **Check existing documentation:**
   - [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md) - Complete setup guide
   - [FIRESTORE_RULES.md](FIRESTORE_RULES.md) - Security rules guide
   - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - General troubleshooting

2. **Gather information:**
   - Exact error message from app/console
   - Screenshot of Indexes tab in Firebase Console
   - Output of `firebase firestore:indexes`
   - Which method you used to create the index

3. **Contact the team:**
   - Open a GitHub issue with the information above
   - Include steps you've already tried
   - Tag with `firebase` and `firestore` labels

---

## Additional Resources

- [Firebase Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
- [Firestore Query Best Practices](https://firebase.google.com/docs/firestore/query-data/queries)
- [Firebase Console](https://console.firebase.google.com)

---

**Last Updated:** February 2026  
**Maintained by:** GUD Express Development Team
