import 'settings_service.dart';

// Existing imports

// ... (rest of the pre-existing file content)

/// Calculate driver earnings with configurable commission rate
/// 
/// This method applies the current commission rate to calculate actual driver earnings.
/// Unlike getDriverEarnings which calculates gross revenue - expenses, this method
/// calculates: (total load revenue * commission rate) - expenses
/// 
/// Parameters:
/// - [driverId]: Driver's user ID (required)
/// - [startDate]: Optional start date for filtering (inclusive)
/// - [endDate]: Optional end date for filtering (inclusive)
/// 
/// Returns: Net earnings after applying commission rate
Future<double> getDriverEarningsWithCommission({
  required String driverId,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  _requireAuth();

  print('💰 Calculating driver earnings with commission for driver: $driverId');

  // Get commission rate from settings
  final settingsService = SettingsService();
  final commissionRate = await settingsService.getDriverCommissionRate();
  final commissionPercent = (commissionRate * 100).toStringAsFixed(1);
  print('   Commission rate: $commissionPercent%');

  // Query total revenue (loads)
  Query loadsQuery = _db.collection('loads').where('driverId', isEqualTo: driverId);
  
  if (startDate != null) {
    loadsQuery = loadsQuery.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
  }
  if (endDate != null) {
    loadsQuery = loadsQuery.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
  }

  print('📦 Querying loads collection...');
  final loadsSnapshot = await loadsQuery.get();
  print('   Found ${loadsSnapshot.docs.length} loads');

  double totalRevenue = loadsSnapshot.docs.fold(0.0, 
    (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rate = (data['rate'] ?? 0) as num;
      return sum + rate.toDouble();
    }
  );
  print('   Total load revenue: \$${totalRevenue.toStringAsFixed(2)}');

  // Apply commission rate
  final driverRevenue = totalRevenue * commissionRate;
  print('   Driver revenue ($commissionPercent%): \$${driverRevenue.toStringAsFixed(2)}');

  // Query total expenses
  Query expensesQuery = _db.collection('expenses').where('driverId', isEqualTo: driverId);
  
  if (startDate != null) {
    expensesQuery = expensesQuery.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
  }
  if (endDate != null) {
    expensesQuery = expensesQuery.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
  }

  print('💸 Querying expenses collection...');
  final expensesSnapshot = await expensesQuery.get();
  print('   Found ${expensesSnapshot.docs.length} expenses');

  double totalExpenses = expensesSnapshot.docs.fold(0.0, 
    (sum, doc) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] ?? 0) as num;
      return sum + amount.toDouble();
    }
  );
  print('   Total expenses: \$${totalExpenses.toStringAsFixed(2)}');

  // Net earnings with commission
  final netEarnings = driverRevenue - totalExpenses;
  print('✅ Net earnings: \$${netEarnings.toStringAsFixed(2)}');

  return netEarnings;
}

// ... (rest of the file content)