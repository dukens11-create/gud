# Maintenance Tracking Query Implementation

## Overview

This implementation provides a best-practice Dart Firestore query service for maintenance tracking in the GUD Express Trucking Management App. The service uses collectionGroup queries to access maintenance records across the entire Firestore hierarchy and provides comprehensive query capabilities with proper ordering, filtering, and real-time streaming.

## Files Added

### 1. `lib/screens/maintenance_tracking.dart` (544 lines)

**Main Component: MaintenanceQueryService**

A comprehensive service class that provides:
- ✅ CollectionGroup queries for accessing maintenance records across all drivers
- ✅ Historical maintenance queries (serviceDate < now)
- ✅ Upcoming maintenance queries (serviceDate >= now)
- ✅ Optional truck number filtering
- ✅ Proper ordering by serviceDate and maintenanceType fields
- ✅ Both one-time fetch and real-time streaming methods
- ✅ Utility methods for statistics and truck number lookup

**Additional Component: MaintenanceRecord**

A type-safe data class with:
- Firestore serialization/deserialization
- Helper methods: `isHistory`, `isUpcoming`, `daysUntilService`, `isNextServiceDue`
- Convenient property access with null safety

### 2. `lib/screens/maintenance_tracking_example.dart` (465 lines)

**Purpose: Demonstration and Reference**

Comprehensive examples showing:
- How to use `streamMaintenanceHistory()` with StreamBuilder
- How to use `getUpcomingMaintenance()` with FutureBuilder
- How to filter by truck number
- How to display maintenance statistics
- How to use the typed MaintenanceRecord class
- Complete UI implementation patterns

### 3. `test/unit/maintenance_query_service_test.dart` (396 lines)

**Purpose: Quality Assurance**

Comprehensive unit tests covering:
- Method signatures and parameter handling
- MaintenanceRecord model transformation
- Business logic validation (isHistory, isUpcoming, daysUntilService)
- Error handling patterns
- Query parameter validation

## Key Features

### 1. CollectionGroup Query

```dart
// Access maintenance records from anywhere in Firestore hierarchy
Query query = _db.collectionGroup('maintenance');
```

This allows querying maintenance records regardless of which driver they belong to, making it efficient and flexible.

### 2. History vs. Upcoming Separation

**History (Past Maintenance):**
```dart
final history = await service.getMaintenanceHistory(
  truckNumber: 'TRK-001',
  limit: 10,
);
```

**Upcoming (Scheduled Maintenance):**
```dart
final upcoming = await service.getUpcomingMaintenance(
  truckNumber: 'TRK-001',
  daysAhead: 30,
  limit: 5,
);
```

### 3. Proper Ordering

All queries order by:
1. **Primary:** `serviceDate` (descending for history, ascending for upcoming)
2. **Secondary:** `maintenanceType` (alphabetically)

This ensures consistent and predictable results.

### 4. Real-Time Streaming

```dart
// Live updates when data changes
StreamBuilder<List<Map<String, dynamic>>>(
  stream: service.streamMaintenanceHistory(truckNumber: 'TRK-001'),
  builder: (context, snapshot) {
    // Build UI with live data
  },
)
```

### 5. Type-Safe Access

```dart
// Use typed MaintenanceRecord for better code quality
final records = recordMaps
    .map((data) => MaintenanceRecord.fromMap(data['id'], data))
    .toList();

// Access properties with type safety
if (record.isHistory) {
  print('Completed ${record.daysUntilService} days ago');
}
```

## API Reference

### MaintenanceQueryService Methods

#### Query Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getMaintenanceHistory()` | `Future<List<Map>>` | Fetch historical records |
| `getUpcomingMaintenance()` | `Future<List<Map>>` | Fetch upcoming records |
| `getAllMaintenance()` | `Future<List<Map>>` | Fetch all records |
| `streamMaintenanceHistory()` | `Stream<List<Map>>` | Stream historical records |
| `streamUpcomingMaintenance()` | `Stream<List<Map>>` | Stream upcoming records |
| `streamAllMaintenance()` | `Stream<List<Map>>` | Stream all records |

#### Utility Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `getMaintenanceStats(String)` | `Future<Map>` | Get statistics for a truck |
| `getTruckNumbersWithMaintenance()` | `Future<List<String>>` | Get all truck numbers |

### Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `truckNumber` | `String?` | Optional filter by truck |
| `limit` | `int?` | Optional result limit |
| `daysAhead` | `int?` | Filter upcoming by days |
| `descending` | `bool` | Sort order (default: true) |

## Usage Examples

### Example 1: Display Historical Maintenance

```dart
FutureBuilder<List<Map<String, dynamic>>>(
  future: service.getMaintenanceHistory(
    truckNumber: 'TRK-001',
    limit: 20,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final records = snapshot.data!;
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return ListTile(
          title: Text(record['maintenanceType']),
          subtitle: Text(record['truckNumber']),
          trailing: Text('\$${record['cost']}'),
        );
      },
    );
  },
)
```

### Example 2: Stream Upcoming Maintenance

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: service.streamUpcomingMaintenance(daysAhead: 30),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final records = snapshot.data!;
    return ListView(
      children: records.map((record) {
        return MaintenanceCard(record: record);
      }).toList(),
    );
  },
)
```

### Example 3: Get Maintenance Statistics

```dart
final stats = await service.getMaintenanceStats('TRK-001');

print('Total maintenance: ${stats['totalCount']}');
print('Total cost: \$${stats['totalCost']}');
print('Upcoming: ${stats['upcomingCount']}');
print('Most recent: ${stats['mostRecentDate']}');
```

### Example 4: Using Typed MaintenanceRecord

```dart
final recordMaps = await service.getAllMaintenance(limit: 10);

final records = recordMaps
    .map((data) => MaintenanceRecord.fromMap(data['id'], data))
    .toList();

for (var record in records) {
  if (record.isHistory) {
    print('${record.maintenanceType} completed ${-record.daysUntilService} days ago');
  } else {
    print('${record.maintenanceType} due in ${record.daysUntilService} days');
  }
  
  if (record.isNextServiceDue) {
    print('⚠️ Next service due soon!');
  }
}
```

## Firestore Index Requirements

The queries use multiple `orderBy` clauses, which require composite indexes in Firestore:

### Required Indexes

1. **maintenance collection group**
   - `serviceDate` (Descending)
   - `maintenanceType` (Ascending)

2. **maintenance collection group** (with truckNumber filter)
   - `truckNumber` (Ascending)
   - `serviceDate` (Descending)
   - `maintenanceType` (Ascending)

Firestore will automatically prompt you to create these indexes when you first run the queries.

## Best Practices Implemented

1. ✅ **Async/await patterns** - All asynchronous operations use modern async/await
2. ✅ **Error handling** - All methods include try-catch with meaningful error messages
3. ✅ **Null safety** - Full null safety with optional parameters
4. ✅ **Documentation** - Comprehensive inline documentation with examples
5. ✅ **Type safety** - Typed MaintenanceRecord class for safer code
6. ✅ **Code reuse** - Utility methods reduce duplication
7. ✅ **Performance** - Efficient queries with proper indexing
8. ✅ **Real-time support** - Stream methods for live data updates
9. ✅ **Flexibility** - Optional parameters for various use cases
10. ✅ **Testing** - Comprehensive unit tests included

## Integration with Existing Code

The service integrates seamlessly with the existing codebase:

- Uses same patterns as `DriverExtendedService`
- Compatible with existing maintenance data structure
- Works with `MaintenanceTrackingScreen` in admin folder
- No breaking changes to existing functionality

## Future Enhancements

Potential improvements that could be added:

1. Pagination support with cursors
2. Additional filters (cost range, date range, service provider)
3. Batch operations for bulk updates
4. Export functionality for maintenance reports
5. Notification integration for upcoming maintenance
6. Search functionality by maintenance type or notes

## Security Considerations

✅ **No vulnerabilities introduced**
- CodeQL security check passed
- No secrets or credentials in code
- Follows Firestore security best practices
- Proper error handling prevents information leakage

## Performance Considerations

1. **Indexing** - Composite indexes ensure fast query performance
2. **Limits** - Optional limit parameter prevents over-fetching
3. **Streams** - Efficient real-time updates with Firestore snapshots
4. **Caching** - Firestore offline persistence enabled by default
5. **CollectionGroup** - Efficient cross-collection queries

## Testing

Run tests with:
```bash
flutter test test/unit/maintenance_query_service_test.dart
```

Tests cover:
- ✅ Method signatures and parameter validation
- ✅ MaintenanceRecord model transformation
- ✅ Business logic (isHistory, isUpcoming, etc.)
- ✅ Error handling patterns
- ✅ Query parameter validation

## Code Review Summary

✅ **Code review completed** with all feedback addressed:
1. ✅ Clarified stream timestamp behavior in documentation
2. ✅ Simplified `isUpcoming` logic for better readability
3. ✅ Added explicit notes about filter boundary stability

## Conclusion

This implementation provides a robust, well-documented, and production-ready solution for maintenance tracking queries in the GUD Express app. It follows best practices, includes comprehensive examples and tests, and integrates seamlessly with the existing codebase.

---

**Implementation Date:** February 10, 2026  
**Status:** ✅ Complete and Ready for Use  
**Files Modified:** 0  
**Files Added:** 3  
**Total Lines:** 1,405
