# Payment System Implementation Guide

## Overview

This guide documents the complete driver payment system where drivers receive **85% of the load revenue** for each delivery. The system automatically creates payment records when loads are delivered and provides comprehensive tracking of pending and completed payments.

## Architecture

### Models

#### Payment Model (`lib/models/payment.dart`)

Represents a driver payment record with the following fields:

- `id`: Unique payment identifier
- `driverId`: Driver's user ID
- `loadId`: Associated load ID
- `amount`: Payment amount (85% of load rate)
- `loadRate`: Original load rate (100%)
- `status`: Payment status ('pending', 'paid', 'cancelled')
- `paymentDate`: When payment was made (null if pending)
- `createdAt`: When payment record was created
- `createdBy`: User who created the payment
- `notes`: Optional notes about the payment

**Computed Properties:**
- `commissionRate`: Returns 0.85 (85% commission)
- `companyShare`: Calculates company's 15% share (loadRate - amount)

### Services

#### PaymentService (`lib/services/payment_service.dart`)

Main service for managing driver payments with the following methods:

##### Core Methods

1. **`calculateDriverPayment(double loadRate)`**
   - Calculates driver payment (85% of load rate)
   - Returns: Driver's payment amount

2. **`createPayment({required driverId, required loadId, required loadRate, notes})`**
   - Creates a payment record when a load is delivered
   - Automatically calculates driver amount (85%)
   - Returns: Payment document ID

3. **`markAsPaid(String paymentId)`**
   - Marks a payment as paid
   - Sets paymentDate to current timestamp
   - Updates status to 'paid'

##### Query Methods

4. **`streamDriverPayments(String driverId)`**
   - Real-time stream of all payments for a driver
   - Ordered by creation time (newest first)
   - Returns: `Stream<List<Payment>>`

5. **`getPendingPayments(String driverId)`**
   - Gets all unpaid payments for a driver
   - Filters by status='pending'
   - Returns: `Future<List<Payment>>`

6. **`getTotalPaidAmount(String driverId, {DateTime? startDate, DateTime? endDate})`**
   - Calculates total amount paid to driver
   - Optional date range filtering
   - Returns: `Future<double>`

7. **`getTotalPendingAmount(String driverId)`**
   - Calculates total pending payment amount
   - Filters by status='pending'
   - Returns: `Future<double>`

8. **`getUnpaidLoads(String driverId)`**
   - Gets all delivered loads that haven't been paid
   - Filters by paymentStatus='unpaid'
   - Returns: `Future<List<LoadModel>>`

9. **`batchCreatePayments(List<String> loadIds)`**
   - Creates payments for multiple loads at once
   - Uses batch writes for atomicity
   - Checks for existing payments
   - Returns: `Future<List<String>>` (payment IDs)

### Integration

#### LoadModel Updates (`lib/models/load.dart`)

Added two new fields:
- `paymentStatus`: Payment status ('unpaid', 'paid', 'partial')
- `paymentId`: Reference to payment document

#### FirestoreService Integration (`lib/services/firestore_service.dart`)

The `updateLoadStatus()` method now automatically:
1. Detects when a load status changes to 'delivered' or 'completed'
2. Checks if payment already exists (via `paymentStatus` field)
3. Creates a payment record using PaymentService
4. Updates the load with payment reference

```dart
// Auto-create payment when load is delivered or completed
if (status == 'delivered' || status == 'completed') {
  await _createPaymentForLoad(loadId);
}
```

## Firestore Structure

### Collections

#### `payments` Collection

Documents in this collection have the following structure:

```json
{
  "driverId": "string",
  "loadId": "string",
  "amount": 850.0,           // 85% of load rate
  "loadRate": 1000.0,        // Original rate
  "status": "pending",       // 'pending', 'paid', 'cancelled'
  "paymentDate": null,       // Timestamp when paid (null if pending)
  "createdAt": "timestamp",
  "createdBy": "string",
  "notes": "string"          // Optional
}
```

#### Updated `loads` Collection Fields

```json
{
  // ... existing fields ...
  "paymentStatus": "unpaid",  // 'unpaid', 'paid', 'partial'
  "paymentId": "payment-123"  // Reference to payment doc
}
```

## Firestore Indexes

The following composite indexes are **REQUIRED** and have been added to `firestore.indexes.json`:

### 1. Stream Driver Payments
**Query:** `streamDriverPayments(driverId)`
```json
{
  "collectionGroup": "payments",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

### 2. Get Pending Payments
**Query:** `getPendingPayments(driverId)`
```json
{
  "collectionGroup": "payments",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

### 3. Get Total Paid Amount with Date Range
**Query:** `getTotalPaidAmount(driverId, startDate, endDate)`
```json
{
  "collectionGroup": "payments",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "paymentDate", "order": "DESCENDING"}
  ]
}
```

### 4. Get Unpaid Loads
**Query:** `getUnpaidLoads(driverId)`
```json
{
  "collectionGroup": "loads",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "driverId", "order": "ASCENDING"},
    {"fieldPath": "paymentStatus", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"}
  ]
}
```

### Deploying Indexes

To deploy these indexes to Firebase:

```bash
firebase deploy --only firestore:indexes
```

Check index status in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes**
4. Wait for all indexes to show "Enabled" status (2-5 minutes for small databases)

## Usage Examples

### Calculate Driver Payment

```dart
final paymentService = PaymentService();
final loadRate = 1000.0;
final driverPayment = paymentService.calculateDriverPayment(loadRate);
// driverPayment = 850.0
```

### Create Payment for Load

```dart
final paymentService = PaymentService();
final paymentId = await paymentService.createPayment(
  driverId: 'driver-123',
  loadId: 'load-456',
  loadRate: 1000.0,
  notes: 'Payment for delivery on Jan 15',
);
```

### Stream Driver Payments

```dart
final paymentService = PaymentService();
Stream<List<Payment>> paymentsStream = 
  paymentService.streamDriverPayments('driver-123');

// In a widget:
StreamBuilder<List<Payment>>(
  stream: paymentsStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final payments = snapshot.data!;
      return ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            title: Text('Load: ${payment.loadId}'),
            subtitle: Text('Status: ${payment.status}'),
            trailing: Text('\$${payment.amount.toStringAsFixed(2)}'),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Get Pending Payments

```dart
final paymentService = PaymentService();
final pendingPayments = await paymentService.getPendingPayments('driver-123');
print('Pending payments: ${pendingPayments.length}');
```

### Calculate Total Paid Amount

```dart
final paymentService = PaymentService();

// All time
final totalPaid = await paymentService.getTotalPaidAmount('driver-123');

// Date range
final startDate = DateTime(2024, 1, 1);
final endDate = DateTime(2024, 1, 31);
final januaryPaid = await paymentService.getTotalPaidAmount(
  'driver-123',
  startDate: startDate,
  endDate: endDate,
);
```

### Batch Create Payments

```dart
final paymentService = PaymentService();
final loadIds = ['load-1', 'load-2', 'load-3'];
final paymentIds = await paymentService.batchCreatePayments(loadIds);
print('Created ${paymentIds.length} payments');
```

## Security

### Authentication

All PaymentService methods require user authentication and use the `_requireAuth()` method to verify:
- User is signed in via Firebase Auth
- Throws `FirebaseAuthException` if not authenticated

### Firestore Rules

Ensure your Firestore security rules allow appropriate access:

```javascript
match /payments/{paymentId} {
  // Drivers can read their own payments
  allow read: if request.auth != null && 
                 resource.data.driverId == request.auth.uid;
  
  // Only admins can create/update payments
  allow create, update: if request.auth != null && 
                           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

match /loads/{loadId} {
  // ... existing rules ...
  
  // Allow updates to payment fields by admin
  allow update: if request.auth != null && 
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' &&
                   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['paymentStatus', 'paymentId']);
}
```

## Testing

### Unit Tests

#### Payment Model Tests (`test/models/payment_test.dart`)
- Constructor validation
- Serialization/deserialization
- Computed properties (commissionRate, companyShare)
- Field handling (required vs optional)
- Numeric type conversions

#### PaymentService Tests (`test/unit/payment_service_test.dart`)
- calculateDriverPayment() accuracy
- Commission rate verification
- Various load rate calculations
- Edge cases (zero, large numbers, decimals)

#### LoadModel Tests (`test/models/load_model_test.dart`)
- Added tests for new payment fields
- Serialization with payment data
- Null handling for payment fields

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/payment_test.dart

# Run with coverage
flutter test --coverage
```

## Commission Breakdown

### Standard Load Example

**Load Rate:** $1,000.00
- **Driver Payment (85%):** $850.00
- **Company Share (15%):** $150.00
- **Total:** $1,000.00

### Formula

```
Driver Payment = Load Rate × 0.85
Company Share = Load Rate × 0.15
or
Company Share = Load Rate - Driver Payment
```

## Workflow

### Automatic Payment Creation Flow

1. Driver completes delivery
2. Driver or admin updates load status to 'delivered' or 'completed'
3. `FirestoreService.updateLoadStatus()` is called
4. Method detects status change to delivered/completed
5. Checks if payment already exists (via `paymentStatus` field)
6. If no payment exists:
   - Creates payment record with status='pending'
   - Calculates driver amount (85% of load rate)
   - Updates load with `paymentId` and `paymentStatus='unpaid'`
7. Payment is now available for admin processing

### Manual Payment Processing

1. Admin queries pending payments via `getPendingPayments()`
2. Admin processes payment externally (bank transfer, check, etc.)
3. Admin calls `markAsPaid(paymentId)` to update record
4. Payment status changes to 'paid' with timestamp

## Best Practices

1. **Always use PaymentService methods** instead of direct Firestore writes
2. **Check for existing payments** before creating new ones
3. **Use batch operations** when processing multiple payments
4. **Monitor indexes** - ensure all required indexes are deployed and enabled
5. **Handle errors gracefully** - payment creation errors shouldn't prevent load status updates
6. **Log payment operations** - all PaymentService methods include detailed logging

## Troubleshooting

### Payment Not Created Automatically

**Check:**
1. Load status is 'delivered' or 'completed'
2. `paymentStatus` field is null or not 'paid'/'unpaid'
3. FirebaseAuth user is authenticated
4. Check console logs for error messages

### Query Requires Index Error

**Solution:**
1. Copy the index creation URL from error message
2. Open URL in browser (Firebase Console)
3. Click "Create Index"
4. Wait 2-5 minutes for index to build
5. Retry operation

### Incorrect Payment Amount

**Check:**
1. Load rate is correct in load document
2. Using `PaymentService.calculateDriverPayment()` method
3. `DRIVER_COMMISSION_RATE` constant is 0.85
4. No manual calculations bypassing the service

## Migration Guide

### For Existing Loads

If you have existing delivered loads without payment records:

```dart
final paymentService = PaymentService();
final firestoreService = FirestoreService();

// Get all delivered loads without payment
final loads = await firestoreService.getDeliveredLoadsWithoutPayment();

// Batch create payments
final loadIds = loads.map((load) => load.id).toList();
await paymentService.batchCreatePayments(loadIds);
```

## Future Enhancements

Potential improvements to consider:

1. **Payment History Export** - CSV export of payment records
2. **Payment Analytics Dashboard** - Visual charts and graphs
3. **Automated Payment Processing** - Integration with payment gateways
4. **Payment Notifications** - Email/SMS alerts for new payments
5. **Dispute Resolution** - System for handling payment disputes
6. **Variable Commission Rates** - Support for different rates per driver/load type
7. **Partial Payments** - Support for split payments
8. **Payment Reminders** - Automated reminders for overdue payments

## Support

For issues or questions about the payment system:
1. Check console logs for detailed error messages
2. Verify all required indexes are deployed and enabled
3. Review Firestore security rules
4. Ensure Firebase Auth is properly configured
5. Check that load data includes all required fields

## Related Documentation

- [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md) - Detailed index setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall application architecture
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Firebase configuration
