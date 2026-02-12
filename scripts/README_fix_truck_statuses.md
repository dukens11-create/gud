# Truck Status Migration Script

## Purpose

This script fixes existing trucks in Firestore that have invalid status values (null, empty, or non-standard values). It ensures all trucks have a valid status from the allowed set: `available`, `in_use`, `maintenance`, or `inactive`.

## Problem Context

Due to a bug in the truck filtering logic, trucks with null, empty, or invalid status values were not appearing in the "Manage Trucks" screen. This script fixes the data to ensure all trucks are visible and have valid statuses.

## Prerequisites

Before running this script, ensure you have:

1. **Firebase Configuration**: The app must be properly configured to connect to Firebase
2. **Authentication**: You must be authenticated with sufficient permissions to update Firestore documents
3. **Flutter/Dart Environment**: Flutter SDK installed and configured

## Usage

### Option 1: Run from Flutter App (Recommended)

The safest way is to run this from within the app context where Firebase is already initialized:

1. Create a temporary admin screen or button that calls:
   ```dart
   import 'scripts/fix_truck_statuses.dart';
   
   // In an admin action
   await fixTruckStatuses();
   ```

2. Run the app in debug mode
3. Navigate to the admin screen and trigger the migration
4. Check the console logs for results

### Option 2: Standalone Dart Script

If running as a standalone script:

```bash
# From the project root
dart scripts/fix_truck_statuses.dart
```

**Note**: This requires proper Firebase initialization. You may need to add Firebase Admin SDK initialization at the top of the script.

## What It Does

1. **Scans all trucks**: Queries all documents in the `trucks` collection
2. **Identifies invalid statuses**: Finds trucks where status is:
   - `null`
   - `""` (empty string)
   - Not in the valid list: `available`, `in_use`, `maintenance`, `inactive`
3. **Updates to 'available'**: Sets the status to `available` (the default for active trucks)
4. **Updates timestamp**: Sets `updatedAt` to the current server timestamp
5. **Reports results**: Shows how many trucks were fixed

## Expected Output

```
🚚 GUD Truck Status Fix Script
================================

🔍 Scanning for trucks with invalid status...
📊 Found 12 truck(s) total
📝 Fixing truck 004 - current status: "null"
📝 Fixing truck 007 - current status: ""
📝 Fixing truck 010 - current status: "broken"

✅ Fixed 3 truck(s) out of 12 total
✅ 9 truck(s) already had valid status

🎉 Migration completed successfully!
```

## After Running

1. **Verify in Firestore**: Check the Firestore console to confirm trucks have valid statuses
2. **Check the App**: Open the "Manage Trucks" screen and verify all trucks are now visible
3. **Test Functionality**: 
   - Toggle "Show Inactive" on/off
   - Verify trucks appear in the list
   - Confirm status badges display correctly
   - Test creating new trucks

## Safety

- **Non-Destructive**: Only updates the `status` and `updatedAt` fields
- **Idempotent**: Safe to run multiple times (skips trucks that already have valid status)
- **No Data Loss**: All other truck data remains unchanged

## Rollback

If you need to rollback the changes, you would need to:

1. Restore from a Firestore backup (if available)
2. Or manually update specific trucks in the Firestore console

**Recommendation**: Take a Firestore backup before running if dealing with production data.

## Related Files

- `lib/models/truck.dart` - Contains the `normalizeStatus()` validation logic
- `lib/services/truck_service.dart` - Updated to use in-memory filtering
- `lib/screens/admin/manage_trucks_screen.dart` - Updated with helpful UI hints
- `test/models/truck_test.dart` - Tests for status normalization

## Support

If you encounter any issues:

1. Check the console logs for detailed error messages
2. Verify Firebase credentials and permissions
3. Ensure you're running from an authenticated context
4. Check that the trucks collection exists and has the expected structure
