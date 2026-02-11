# Firestore Migration Scripts

This directory contains scripts to migrate and fix data in Firestore.

## 🔧 fix_status_values.dart

Fixes status values in the `loads` collection by updating `'in-transit'` (hyphen) to `'in_transit'` (underscore).

### Why This Is Needed

The app's filter UI uses `'in_transit'` (underscore) but some loads in the database might have `'in-transit'` (hyphen). This mismatch causes:
- ❌ Firestore index errors
- ❌ Filter not working correctly
- ❌ No loads showing when "In Transit" filter is selected

### How to Run

1. **Make sure Firebase is configured** - The script needs your Firebase credentials

2. **Run the script:**
   ```bash
   dart run scripts/fix_status_values.dart
   ```

3. **What happens:**
   - 📊 Queries all loads with status `'in-transit'`
   - 🔄 Updates each one to `'in_transit'`
   - ✅ Shows progress for each load
   - 📈 Reports total success/error count

### Expected Output

```
🔧 Starting status value migration...

📊 Querying loads with status "in-transit"...
📝 Found 5 loads to update

✅ Updated load: abc123 (LOAD-001)
✅ Updated load: def456 (LOAD-002)
✅ Updated load: ghi789 (LOAD-003)
✅ Updated load: jkl012 (LOAD-004)
✅ Updated load: mno345 (LOAD-005)

📊 Migration Complete!
   ✅ Successfully updated: 5 loads

🎉 Status values have been fixed!
   Old value: "in-transit" (hyphen)
   New value: "in_transit" (underscore)
```

### If No Changes Needed

```
🔧 Starting status value migration...

📊 Querying loads with status "in-transit"...
✅ No loads found with "in-transit" status.
   All status values are already correct!
```

### Safety

- ✅ **Safe to run multiple times** - Only updates loads that need fixing
- ✅ **No data loss** - Only changes the `status` field
- ✅ **Shows all changes** - You can see exactly what was updated
- ✅ **Error handling** - Continues even if individual updates fail

### After Running

1. ✅ Restart your app (if running)
2. ✅ Try the "In Transit" filter in the driver dashboard
3. ✅ Should now work without errors!

### Troubleshooting

**Error: Firebase not initialized**
```
Make sure you have:
- Firebase configured in your project
- firebase_options.dart file generated
- Run: flutterfire configure
```

**Error: Permission denied**
```
Check your Firestore security rules:
- Make sure your service account has write access
- Or run this from an authenticated admin context
```

**No loads found but filter still doesn't work**
```
The issue might be:
1. Firestore index still building (wait 5-10 minutes)
2. App cache (run: flutter clean && flutter run)
3. Different issue (check console logs)
```
