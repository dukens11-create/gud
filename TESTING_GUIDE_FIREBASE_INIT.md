# Testing Guide - Firebase Truck Initialization

## Overview
This guide provides step-by-step instructions for testing the Firebase truck initialization feature.

## Prerequisites
- Firebase project configured and connected
- Admin user account created
- Firebase Authentication enabled
- Firestore database enabled
- Firestore security rules deployed

## Testing Scenarios

### Scenario 1: First-Time Initialization (Automatic)

**Goal**: Verify automatic initialization when admin first opens ManageTrucksScreen

**Steps**:
1. Ensure Firestore `trucks` collection is empty (or non-existent)
   - Open Firebase Console
   - Navigate to Firestore Database
   - Delete all documents in `trucks` collection if it exists

2. Build and run the app:
   ```bash
   flutter run
   ```

3. Log in as an admin user
   - Use admin credentials
   - Complete email verification if required

4. Navigate to ManageTrucksScreen:
   - From admin home, tap "Manage Trucks"
   - Or navigate to `/admin/trucks` route

5. **Expected Result**:
   - Screen loads successfully
   - Loading indicator appears briefly
   - 5 sample trucks appear automatically:
     * TRK-001: Ford F-150 (2022) - Available
     * TRK-002: Chevrolet Silverado (2021) - Available
     * TRK-003: RAM 1500 (2023) - In Use
     * TRK-004: Toyota Tundra (2020) - In Use
     * TRK-005: GMC Sierra (2021) - Maintenance

6. Verify in Firebase Console:
   - Open Firestore Database
   - Navigate to `trucks` collection
   - Confirm 5 documents exist with correct data

### Scenario 2: Manual Initialization (Debug Mode)

**Goal**: Verify manual initialization via debug button

**Steps**:
1. Ensure app is running in debug mode:
   ```bash
   flutter run --debug
   ```

2. Log in as admin and navigate to ManageTrucksScreen

3. Look for refresh button (🔄) in AppBar
   - Should be visible only in debug mode
   - Located in top-right area of AppBar

4. Tap the refresh button

5. **Expected Result**:
   - Confirmation dialog appears:
     * Title: "Re-initialize Sample Data"
     * Message: Explains this is a debug feature
     * Buttons: "Cancel" and "Initialize"

6. Tap "Initialize"

7. **Expected Result**:
   - Dialog closes
   - Success message appears: "Sample data initialized successfully"
   - 5 new trucks are created in Firestore

8. Verify duplicate prevention:
   - Tap refresh button again
   - Tap "Initialize"
   - **Expected**: "Sample data already exists or initialization skipped"

### Scenario 3: Initialization with Existing Data

**Goal**: Verify initialization is skipped when trucks already exist

**Steps**:
1. Ensure `trucks` collection has at least 1 document

2. Restart the app and log in as admin

3. Navigate to ManageTrucksScreen

4. **Expected Result**:
   - Existing trucks are displayed
   - No new trucks are created
   - Console shows: "✅ Trucks collection already has data, skipping initialization"

### Scenario 4: Permission Errors

**Goal**: Verify graceful handling of permission errors

**Steps**:
1. Temporarily update Firestore rules to deny truck creation:
   ```
   allow create: if false;
   ```

2. Clear `trucks` collection

3. Log in as admin and navigate to ManageTrucksScreen

4. **Expected Result**:
   - Screen loads without crashing
   - No sample trucks are created
   - Console shows error message
   - Screen displays "No trucks found" message

5. Restore Firestore rules:
   ```
   allow create, update: if isAdmin();
   ```

6. Use debug button to manually initialize

7. **Expected Result**:
   - Trucks are created successfully

### Scenario 5: Non-Admin User

**Goal**: Verify non-admin users don't trigger initialization

**Steps**:
1. Log in as a driver (non-admin) user

2. Attempt to navigate to ManageTrucksScreen
   - Should be blocked by route guards

3. **Expected Result**:
   - Driver users cannot access ManageTrucksScreen
   - No initialization is triggered

### Scenario 6: Offline Mode

**Goal**: Verify graceful handling when offline

**Steps**:
1. Enable airplane mode or disable network

2. Log in (cached credentials)

3. Navigate to ManageTrucksScreen

4. **Expected Result**:
   - Screen shows cached data (if any)
   - Initialization silently fails
   - No error is shown to user
   - Console shows network error

5. Re-enable network

6. Pull to refresh or restart app

7. **Expected Result**:
   - Initialization runs successfully

## Verification Checklist

After completing the above scenarios, verify:

- [ ] Sample trucks appear automatically on first admin access
- [ ] Debug button is visible only in debug mode
- [ ] Manual initialization creates trucks successfully
- [ ] Duplicate initialization is prevented
- [ ] Existing data is not overwritten
- [ ] Permission errors are handled gracefully
- [ ] Non-admin users cannot trigger initialization
- [ ] Offline mode doesn't crash the app
- [ ] All 5 sample trucks have correct data
- [ ] Truck status badges display correctly (Available, In Use, Maintenance)

## Sample Truck Data to Verify

| Truck # | Make | Model | Year | Plate | Status | VIN | Notes |
|---------|------|-------|------|-------|--------|-----|-------|
| TRK-001 | Ford | F-150 | 2022 | GUD-1234 | Available | 1HGBH41JXMN109186 | Capacity: 1000 lbs |
| TRK-002 | Chevrolet | Silverado | 2021 | EXP-5678 | Available | 2HGBH41JXMN109187 | Capacity: 1500 lbs |
| TRK-003 | RAM | 1500 | 2023 | TRK-9012 | In Use | 3HGBH41JXMN109188 | Capacity: 1200 lbs |
| TRK-004 | Toyota | Tundra | 2020 | FLT-3456 | In Use | 4HGBH41JXMN109189 | Capacity: 1100 lbs |
| TRK-005 | GMC | Sierra | 2021 | COM-7890 | Maintenance | 5HGBH41JXMN109190 | Capacity: 1300 lbs |

## Console Output to Expect

### Successful Initialization
```
🚛 Checking trucks collection...
📝 Trucks collection is empty, creating sample trucks...
✅ Successfully created 5 sample trucks
```

### Skipped (Data Exists)
```
🚛 Checking trucks collection...
✅ Trucks collection already has data, skipping initialization
```

### No Authentication
```
🚛 Checking trucks collection...
ℹ️ No user authenticated, skipping truck initialization
```

### Permission Error
```
🚛 Checking trucks collection...
📝 Trucks collection is empty, creating sample trucks...
❌ Error initializing trucks: [firebase_firestore/permission-denied] ...
```

## Troubleshooting

### Issue: Trucks Don't Appear

**Possible Causes**:
1. User not authenticated
2. User not an admin
3. Firestore security rules deny access
4. Network error

**Solutions**:
1. Verify user is logged in as admin
2. Check Firestore security rules:
   ```
   allow read: if isAuthenticated();
   allow create, update: if isAdmin();
   ```
3. Check console for error messages
4. Verify network connectivity
5. Use debug button to manually trigger initialization

### Issue: Debug Button Not Visible

**Possible Causes**:
1. App running in release mode
2. Not on ManageTrucksScreen

**Solutions**:
1. Run app with: `flutter run --debug`
2. Navigate to ManageTrucksScreen
3. Check that `kDebugMode` is true

### Issue: Duplicate Trucks Created

**Possible Causes**:
1. Multiple rapid initializations
2. Race condition

**Solutions**:
1. Check Firestore for duplicate documents
2. Delete duplicates manually
3. The service should prevent duplicates - report as bug if occurring

### Issue: Permission Denied Error

**Possible Causes**:
1. User not an admin
2. Firestore rules too restrictive
3. User role not set in Firestore

**Solutions**:
1. Verify user document in Firestore has `role: 'admin'`
2. Check Firestore security rules
3. Update user role if needed
4. Redeploy Firestore rules if modified

## Performance Testing

### Batch Write Performance
1. Time how long initialization takes
2. Expected: < 2 seconds for 5 trucks
3. Monitor Firestore usage in console

### Memory Usage
1. Check memory before initialization
2. Check memory after initialization
3. Should be minimal increase (<1 MB)

### Network Usage
1. Monitor network tab in dev tools
2. Should see 1-2 Firestore requests:
   - GET to check if trucks exist
   - POST for batch write (if needed)

## Automated Testing

Run unit tests:
```bash
flutter test test/unit/firebase_init_service_test.dart
```

Expected output:
```
✓ service can be instantiated
✓ should be callable without throwing immediately
✓ returns Future<bool>
✓ sample truck structure matches Truck model requirements
```

## Integration Testing

For full integration testing with Firebase:

1. Set up Firebase emulators:
   ```bash
   firebase emulators:start
   ```

2. Run integration tests:
   ```bash
   flutter test integration_test/
   ```

## Production Testing

Before deploying to production:

1. Test in staging environment
2. Verify Firestore security rules
3. Test with real admin account
4. Verify analytics events
5. Check crash reporting integration
6. Test on multiple devices (iOS, Android, Web)

## Reporting Issues

If you encounter issues, provide:
1. Console output
2. Firestore rules configuration
3. User role in Firestore
4. Steps to reproduce
5. Expected vs actual behavior
6. Screenshots if applicable

## Next Steps

After successful testing:
1. Mark PR as ready for review
2. Update project documentation
3. Train admins on debug button usage
4. Monitor production for any issues
5. Consider adding more sample data (drivers, loads, etc.)
