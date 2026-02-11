# Database Migration Scripts

## Fix Status Values Script

### Problem
The app's "In Transit" filter uses `'in_transit'` (underscore), but some loads in Firestore might have `'in-transit'` (hyphen). This causes the filter to fail with an index error.

### Solution
Run the migration script to update all status values from `'in-transit'` to `'in_transit'`.

### How to Run

1. **Make sure you have Firebase configured:**
   ```bash
   # If you haven't already, run:
   flutter pub get
   ```

2. **Run the migration script:**
   ```bash
   dart run scripts/fix_status_values.dart
   ```

3. **What the script does:**
   - Finds all loads with status `'in-transit'`
   - Updates them to `'in_transit'`
   - Shows progress for each updated load
   - Reports total success/failure count

### Example Output

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

### After Running

1. The "In Transit" filter should work immediately
2. No app code changes needed
3. Run the app and test the filter

### Safety

- The script only updates the `status` field
- It doesn't affect any other data
- You can run it multiple times safely (it won't find any documents after the first run)

## Need Help?

If the script fails, check:
- Firebase connection is working
- You have write permissions to Firestore
- The Firebase project is correctly configured
