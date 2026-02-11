# Tools Directory

This directory contains utility scripts and tools for managing the GUD Express Trucking Management App.

## Migration Scripts

### migrate_driver_names.dart

**Purpose:** Updates existing load documents to include the `driverName` field.

**Background:** 
Previously, loads only stored the `driverId` field. The app has been updated to also store and display the `driverName` for better user experience. This migration script updates historical data to include driver names.

**What it does:**
1. Fetches all loads from Firestore that don't have a `driverName` field
2. Looks up each driver's name using their `driverId`
3. Updates the load document with the driver's name
4. Provides a detailed summary of the migration

**Prerequisites:**
- Firebase project must be properly configured
- You need appropriate Firestore permissions to read/write data
- The Flutter/Dart environment must be set up

**Usage:**

```bash
# Run the migration script
cd /path/to/gud
dart tools/migrate_driver_names.dart
```

**Expected Output:**
```
🚀 Starting driver name migration...

📦 Fetching all loads from Firestore...
   Found 150 total loads

📋 Found 75 loads without driver names

👥 Fetching driver information...
   Loaded 25 drivers

🔄 Updating loads with driver names...
   ✓ Load abc123: Updated with driver name "John Smith"
   ✓ Load def456: Updated with driver name "Jane Doe"
   ...

============================================================
Migration Summary:
============================================================
✅ Successfully updated: 75 loads
⚠️  Skipped: 0 loads
❌ Errors: 0 loads
📊 Total processed: 75 loads
============================================================

✅ Migration completed successfully!
   All loads now have driver names populated.
```

**Important Notes:**
- **New loads**: All new loads created after the fix will automatically have driver names populated
- **Old loads**: Only loads created before this fix need migration
- **Safe to re-run**: The script only updates loads that don't have a `driverName` field
- **Backup recommendation**: Consider backing up your Firestore data before running migrations

**Troubleshooting:**

If you encounter errors:

1. **Permission denied**: Ensure your Firebase credentials have read/write access to the `loads` and `drivers` collections
2. **Firebase not initialized**: Make sure Firebase is properly configured in your project
3. **Driver not found**: Some loads may reference drivers that no longer exist - these will be skipped

**Alternative: Firebase Console**

You can also manually update loads through the Firebase Console:
1. Go to Firestore Database in Firebase Console
2. Navigate to the `loads` collection
3. For each load, click Edit
4. Add a field: `driverName` (string) with the appropriate driver's name
5. Save the document

This manual approach is suitable for small numbers of loads but the script is recommended for bulk updates.
