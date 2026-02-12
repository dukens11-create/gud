# Driver Load Visibility - Debug Guide

## Overview

This guide helps diagnose and fix issues when drivers cannot see loads assigned to them in the GUD Express app.

## Quick Checklist

When a driver reports they cannot see their assigned loads, verify these items in order:

- [ ] Driver is logged in with correct account
- [ ] Loads exist in Firestore with correct `driverId`
- [ ] Status values use underscores (`in_transit` not `in-transit`)
- [ ] Firestore indexes are deployed and built
- [ ] Firestore security rules allow driver access
- [ ] No Firestore errors in console logs

## Common Issues & Solutions

### Issue 1: No Loads Showing (But Loads Exist)

**Symptoms:**
- Driver sees "No loads assigned yet" message
- Admin can see loads assigned to the driver
- Console shows "Received 0 load documents"

**Root Causes & Solutions:**

#### A. Incorrect driverId Field

**Problem:** The `driverId` field in the load doesn't match the driver's Firebase Auth UID.

**How to Check:**
1. Get driver's Firebase Auth UID:
   - Look at console logs: `👤 Current authenticated user UID: xxx`
   - Or check Firebase Console > Authentication
2. Check load's driverId in Firestore:
   - Firebase Console > Firestore > loads collection
   - Find the load and check the `driverId` field

**Solution:**
- Loads must have `driverId` set to the driver's Firebase Auth UID
- When creating loads, use: `driverId: driver.uid` (Firebase Auth UID)
- Do NOT use: driver email, name, or custom ID

**Fix Existing Loads:**
```javascript
// Run in Firestore console or script
db.collection('loads').doc('LOAD_ID').update({
  driverId: 'CORRECT_FIREBASE_AUTH_UID'
});
```

#### B. Firestore Security Rules Block Access

**Problem:** Security rules prevent driver from reading loads.

**How to Check:**
1. Look for permission errors in console:
   - `⚠️ Permission denied - check Firestore security rules`
   - `PERMISSION_DENIED` errors
2. Check Firestore rules in Firebase Console

**Required Rule:**
```javascript
match /loads/{loadId} {
  allow read: if isAuthenticated() && 
                 (isAdmin() || resource.data.driverId == request.auth.uid);
}
```

**Solution:**
- Ensure rule allows: `resource.data.driverId == request.auth.uid`
- Deploy rules: `firebase deploy --only firestore:rules`

#### C. Firestore Index Missing or Building

**Problem:** Composite index required but not available.

**How to Check:**
1. Look for index errors in console:
   - `⚠️ Firestore index required`
   - Error messages mentioning "index"
2. Check Firebase Console > Firestore > Indexes

**Required Indexes:**

For "All" loads:
```json
{
  "collectionGroup": "loads",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

For status filters (assigned, in_transit, delivered):
```json
{
  "collectionGroup": "loads",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

**Solution:**
1. Check `firestore.indexes.json` has required indexes
2. Deploy indexes: `firebase deploy --only firestore:indexes`
3. Wait 2-5 minutes for indexes to build
4. Check status: Firebase Console > Firestore > Indexes
5. Index should show "Enabled" status (not "Building")

### Issue 2: Status Filter Shows No Results

**Symptoms:**
- "All" filter shows loads correctly
- Specific status filter (Assigned, In Transit, Delivered) shows no results
- Console shows "Received 0 load documents for driver XXX with status YYY"

**Root Causes & Solutions:**

#### A. Incorrect Status Values (Hyphens vs Underscores)

**Problem:** Status values in database use hyphens instead of underscores.

**How to Check:**
1. Check console logs for status value warnings:
   - `⚠️ WARNING: Status contains hyphen!`
   - `Expected: "in_transit", Got: "in-transit"`
2. Check load status in Firestore console

**Correct Status Values:**
- ✅ `assigned` (underscore - already correct)
- ✅ `in_transit` (underscore)
- ✅ `delivered` (underscore - already correct)
- ❌ `in-transit` (hyphen - WRONG!)

**Solution:**
- Update any loads with incorrect status values
- Use the migration script: `dart run scripts/fix_status_values.dart`
- Or manually update in Firestore console

#### B. Loads Have Different Status

**Problem:** Loads exist but don't match the selected status.

**How to Check:**
1. Switch to "All" filter to see all loads
2. Check status badges on load cards
3. Verify loads have the expected status

**Solution:**
- If loads show different status than expected, they may be:
  - Still in 'assigned' status (haven't started trip)
  - Already 'delivered' (trip completed)
- Admin may need to update load status if incorrect

### Issue 3: Intermittent Loading Issues

**Symptoms:**
- Loads sometimes appear, sometimes don't
- Works after app restart or page refresh
- Inconsistent behavior

**Root Causes & Solutions:**

#### A. Index Still Building

**Problem:** Firestore index is being built after deployment.

**How to Check:**
- Firebase Console > Firestore > Indexes
- Status shows "Building" instead of "Enabled"

**Solution:**
- Wait for index to complete (usually 2-5 minutes)
- Large datasets may take longer
- Do not query with status filter until index is "Enabled"

#### B. Network or Firestore Connection Issues

**Problem:** Network connectivity or Firestore backend issues.

**How to Check:**
1. Check console for connection errors
2. Test with different status filters
3. Try refreshing the page

**Solution:**
- Check internet connection
- Retry after a few moments
- Contact Firebase support if persistent

## Console Log Reference

### Successful Load Query

```
🔍 Getting filtered loads - Status filter: assigned, Driver ID: abc123
👤 Current authenticated user UID: abc123
🎯 Query filters: driverId == abc123 AND status == assigned
⚠️ Status value check: "assigned" (must use underscores, e.g., "in_transit")
📊 Received 3 load documents for driver abc123 with status assigned
   ✓ Load LOAD-001: status=assigned, driverId=abc123, createdAt=2024-02-11
   ✓ Load LOAD-002: status=assigned, driverId=abc123, createdAt=2024-02-10
   ✓ Load LOAD-003: status=assigned, driverId=abc123, createdAt=2024-02-09
✅ Received 3 loads from Firestore with status assigned
```

### Empty Result (Expected)

```
🔍 Getting filtered loads - Status filter: delivered, Driver ID: abc123
👤 Current authenticated user UID: abc123
🎯 Query filters: driverId == abc123 AND status == delivered
📊 Received 0 load documents for driver abc123 with status delivered
ℹ️  No loads found for driver abc123 with status delivered
   💡 Debug tips:
      1. Verify loads exist in Firestore with driverId = abc123 AND status = delivered
      2. Check status value uses underscores (in_transit) not hyphens (in-transit)
      3. Ensure load assignment sets correct status value
      4. Verify Firestore security rules allow driver to read their loads
      5. Check Firestore indexes are deployed and enabled
✅ Received 0 loads from Firestore with status delivered
```

### Permission Error

```
❌ Error in filtered loads stream: [cloud_firestore/permission-denied] ...
⚠️  Permission denied - check Firestore security rules
   Ensure rules allow: if resource.data.driverId == request.auth.uid
   Current user UID: abc123
   Query driverId: abc123
```

### Index Error

```
❌ Error streaming driver loads by status: [cloud_firestore/failed-precondition] ...
⚠️  FIRESTORE INDEX REQUIRED ⚠️

This query requires a composite index to work efficiently.

Query details:
- Collection: loads
- Filters: driverId = abc123, status = assigned
- OrderBy: createdAt (descending)

IMMEDIATE ACTION REQUIRED:
...
```

### Status Value Warning

```
⚠️  WARNING: Status contains hyphen! This may cause no results.
   Expected: "in_transit", Got: "in-transit"
```

## Testing Procedure

### Manual Test with Driver Account

1. **Login as driver:**
   - Use test driver account credentials
   - Note the driver's Firebase Auth UID from console logs

2. **Create test load as admin:**
   - Login as admin
   - Create new load
   - Assign to test driver
   - Set status to 'assigned'
   - **Verify**: Check Firestore console that `driverId` matches driver's UID

3. **Verify driver can see load:**
   - Switch back to driver account
   - Navigate to driver home screen
   - Should see load in "All" filter
   - Should see load in "Assigned" filter
   - Check console logs for successful query

4. **Test status filters:**
   - Tap "Assigned" - should show the test load
   - Tap "In Transit" - should show no results (load is not in_transit yet)
   - Tap "Delivered" - should show no results (load not delivered yet)

5. **Test status changes:**
   - As driver, start trip on the test load
   - Status should change to 'in_transit'
   - Load should disappear from "Assigned" filter
   - Load should appear in "In Transit" filter

### Automated Test (Unit Test)

```dart
testWidgets('Driver sees only their assigned loads', (tester) async {
  // Setup
  final driverId = 'test-driver-123';
  
  // Create test loads in Firestore
  await createTestLoad(loadId: 'load-1', driverId: driverId, status: 'assigned');
  await createTestLoad(loadId: 'load-2', driverId: 'other-driver', status: 'assigned');
  
  // Render driver home with driverId
  await tester.pumpWidget(MaterialApp(
    home: DriverHome(driverId: driverId),
  ));
  await tester.pumpAndSettle();
  
  // Verify only load-1 is visible
  expect(find.text('load-1'), findsOneWidget);
  expect(find.text('load-2'), findsNothing);
});
```

## Deployment Checklist

Before deploying changes:

- [ ] Verify `firestore.indexes.json` has all required indexes
- [ ] Deploy indexes: `firebase deploy --only firestore:indexes`
- [ ] Wait for indexes to build (check Firebase Console)
- [ ] Verify Firestore security rules allow driver access
- [ ] Test with real driver account
- [ ] Check console logs for errors
- [ ] Verify all status filters work correctly
- [ ] Test with empty state (driver with no loads)

## Support Resources

- **Firestore Console**: https://console.firebase.google.com/project/_/firestore
- **Index Management**: https://console.firebase.google.com/project/_/firestore/indexes
- **Security Rules**: https://console.firebase.google.com/project/_/firestore/rules
- **Authentication**: https://console.firebase.google.com/project/_/authentication/users

## Additional Documentation

- `DRIVER_LOAD_ASSIGNMENT_FIX.md` - Previous fix for missing indexes
- `IMPLEMENTATION_FIRESTORE_QUERIES.md` - Query optimization details
- `FIRESTORE_INDEX_SETUP.md` - Index setup guide
- `MANUAL_VERIFICATION_CHECKLIST.md` - Testing procedures
- `pull_requests/2026-02-11-18-48-54.md` - Status value fix PR
