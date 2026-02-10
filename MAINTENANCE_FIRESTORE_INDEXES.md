# Firestore Composite Indexes for Maintenance Tracking

## Overview

This document explains the Firestore composite indexes required for the maintenance tracking query service. These indexes are essential for efficient querying of maintenance records across the entire Firestore database using collection group queries.

## Why Composite Indexes Are Needed

The `MaintenanceQueryService` in `lib/screens/maintenance_tracking.dart` uses collection group queries with multiple `orderBy` clauses. Firestore requires composite indexes when:
1. Using multiple `orderBy` clauses
2. Combining `where` clauses with `orderBy` on different fields
3. Using collection group queries (accessing a collection across all documents)

## Indexes Added to firestore.indexes.json

### 1. Basic Maintenance Query (Descending Order)
**Use Case**: Historical maintenance records (most recent first)

```json
{
  "collectionGroup": "maintenance",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "serviceDate",
      "order": "DESCENDING"
    },
    {
      "fieldPath": "maintenanceType",
      "order": "ASCENDING"
    }
  ]
}
```

**Supports queries like**:
```dart
// Get all historical maintenance, most recent first
await service.getMaintenanceHistory();

// Stream all maintenance records
stream: service.streamAllMaintenance(descending: true)
```

### 2. Basic Maintenance Query (Ascending Order)
**Use Case**: Upcoming maintenance records (soonest first)

```json
{
  "collectionGroup": "maintenance",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "serviceDate",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "maintenanceType",
      "order": "ASCENDING"
    }
  ]
}
```

**Supports queries like**:
```dart
// Get upcoming maintenance, soonest first
await service.getUpcomingMaintenance();

// Stream all maintenance in ascending order
stream: service.streamAllMaintenance(descending: false)
```

### 3. Filtered by Truck Number (Descending Order)
**Use Case**: Historical maintenance for a specific truck

```json
{
  "collectionGroup": "maintenance",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "truckNumber",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "serviceDate",
      "order": "DESCENDING"
    },
    {
      "fieldPath": "maintenanceType",
      "order": "ASCENDING"
    }
  ]
}
```

**Supports queries like**:
```dart
// Get historical maintenance for specific truck
await service.getMaintenanceHistory(truckNumber: 'TRK-001');

// Stream maintenance for specific truck
stream: service.streamMaintenanceHistory(truckNumber: 'TRK-001')
```

### 4. Filtered by Truck Number (Ascending Order)
**Use Case**: Upcoming maintenance for a specific truck

```json
{
  "collectionGroup": "maintenance",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {
      "fieldPath": "truckNumber",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "serviceDate",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "maintenanceType",
      "order": "ASCENDING"
    }
  ]
}
```

**Supports queries like**:
```dart
// Get upcoming maintenance for specific truck
await service.getUpcomingMaintenance(truckNumber: 'TRK-001');

// Get all maintenance for truck in ascending order
await service.getAllMaintenance(
  truckNumber: 'TRK-001',
  descending: false,
);
```

## Index Deployment

### Automatic Deployment (Recommended)
When deploying with Firebase CLI, the indexes will be created automatically:

```bash
# Deploy all Firebase configuration including indexes
firebase deploy --only firestore:indexes

# Or deploy everything
firebase deploy
```

### Manual Creation
Alternatively, indexes can be created manually in the Firebase Console:
1. Go to Firebase Console > Firestore Database > Indexes
2. Click "Create Index"
3. Set Collection Group ID: `maintenance`
4. Add fields according to the configurations above
5. Click "Create Index"

### Development Testing
When testing locally with the Firebase emulator:

```bash
# Start Firestore emulator
firebase emulators:start --only firestore

# The emulator will auto-generate indexes as they're needed
# Export them after testing:
firebase emulators:export ./emulator-data
```

## Query Performance Considerations

### Index Coverage
These 4 indexes provide complete coverage for all maintenance queries:
- ✅ All maintenance records (both orders)
- ✅ Historical maintenance (descending)
- ✅ Upcoming maintenance (ascending)
- ✅ Filtered by truck number (both orders)
- ✅ Combined with limit parameter
- ✅ Combined with time-based filters

### Query Patterns Supported

| Query Method | Filter | Order | Index Used |
|-------------|--------|-------|-----------|
| `getAllMaintenance()` | None | DESC | Index #1 |
| `getAllMaintenance()` | None | ASC | Index #2 |
| `getAllMaintenance()` | truckNumber | DESC | Index #3 |
| `getAllMaintenance()` | truckNumber | ASC | Index #4 |
| `getMaintenanceHistory()` | None | DESC | Index #1 |
| `getMaintenanceHistory()` | truckNumber | DESC | Index #3 |
| `getUpcomingMaintenance()` | None | ASC | Index #2 |
| `getUpcomingMaintenance()` | truckNumber | ASC | Index #4 |

### Additional Filters
The queries also use additional filters that are automatically handled by Firestore:
- `serviceDate` comparisons (`<`, `>=`, `<=`)
- These work with the composite indexes above without requiring additional indexes

## Index Monitoring

### Check Index Status
In Firebase Console:
1. Go to Firestore Database > Indexes
2. Check status of each index:
   - 🟢 **Enabled**: Ready to use
   - 🟡 **Building**: Being created (can take minutes to hours)
   - 🔴 **Error**: Failed to create (check configuration)

### Index Build Time
- Small databases: Usually < 1 minute
- Medium databases (1K-10K docs): 1-5 minutes
- Large databases (100K+ docs): Can take hours

The app will still work during index building, but queries will be slower.

## Troubleshooting

### Error: "The query requires an index"
**Solution**: Deploy the indexes using `firebase deploy --only firestore:indexes`

### Error: "Index already exists"
**Solution**: This is normal - Firestore won't create duplicates. You can safely ignore this.

### Query is slow despite indexes
**Possible causes**:
1. Index is still building (check Firebase Console)
2. Large result sets (use `limit` parameter)
3. Network latency (use offline persistence)

### Query fails with "permission denied"
**Note**: This is not an index issue. Check your Firestore security rules in `firestore.rules`.

## Best Practices

1. ✅ **Deploy indexes before deployment**: Always deploy indexes before deploying app updates that use new query patterns
2. ✅ **Test with emulator**: Use Firebase emulator during development to validate queries
3. ✅ **Monitor index build**: Large databases may take time to build indexes
4. ✅ **Use limits**: Always use `limit` parameter when appropriate to prevent over-fetching
5. ✅ **Offline support**: Enable Firestore offline persistence for better performance

## Related Files

- **Index Configuration**: `firestore.indexes.json`
- **Query Service**: `lib/screens/maintenance_tracking.dart`
- **Example Usage**: `lib/screens/maintenance_tracking_example.dart`
- **Tests**: `test/unit/maintenance_query_service_test.dart`
- **Documentation**: `MAINTENANCE_TRACKING_IMPLEMENTATION.md`

## Security Rules Integration

These indexes work with your Firestore security rules. Make sure your `firestore.rules` file allows:
- Read access to maintenance records for authorized users
- Write access for maintenance record creation/updates

Example rule snippet:
```javascript
match /drivers/{driverId}/maintenance/{maintenanceId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
               (request.auth.uid == driverId || 
                get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
}
```

## Summary

✅ **4 composite indexes added** to support all maintenance tracking queries  
✅ **Complete query coverage** for all use cases  
✅ **Optimal performance** with proper ordering and filtering  
✅ **Collection group support** for cross-driver queries  
✅ **Ready for deployment** with `firebase deploy --only firestore:indexes`

---

**Last Updated**: February 10, 2026  
**Status**: ✅ Ready for deployment  
**Indexes**: 4 composite indexes for maintenance collection group
