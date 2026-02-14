import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

/// Expense tracking service for managing business expenses.
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
///
/// ============================================================================
/// FIRESTORE COMPOSITE INDEX ANALYSIS
/// ============================================================================
/// 
/// **ROOT CAUSE OF INDEX ERRORS:**
/// The 'expenses' collection had NO composite indexes defined in firestore.indexes.json
/// despite multiple queries requiring them. This caused "query requires an index" errors.
///
/// **QUERIES REQUIRING COMPOSITE INDEXES:**
/// 
/// 1. streamDriverExpenses(driverId) - Used by "My Expenses" driver screen
///    - Query: .where('driverId', ==).orderBy('date', descending: true)
///    - Required Index: driverId ASC + date DESC
///    - Status: ✅ ADDED to firestore.indexes.json
///
/// 2. streamLoadExpenses(loadId) - Used for load-specific expense tracking
///    - Query: .where('loadId', ==).orderBy('date', descending: true)  
///    - Required Index: loadId ASC + date DESC
///    - Status: ✅ ADDED to firestore.indexes.json
///
/// 3. getExpensesByCategory(driverId, startDate, endDate) - Used for analytics
///    - Query: .where('driverId', ==).where('date', >=).where('date', <=)
///    - Required Index: driverId ASC + date ASC
///    - Status: ✅ ADDED to firestore.indexes.json
///    - Note: Date range queries on same field work with single-field index
///
/// 4. StatisticsService.calculateStatistics() - Cross-service query
///    - Query: .where('date', >=).where('date', <=) + optional .where('driverId', ==)
///    - Required Index: driverId ASC + date ASC (when driverId filter used)
///    - Status: ✅ Covered by index #3 above
///
/// **QUERIES NOT REQUIRING COMPOSITE INDEX:**
/// - streamAllExpenses(): Only uses .orderBy('date') - single-field index (auto-created)
///
/// **DEPLOYMENT INSTRUCTIONS:**
/// After merging these changes:
/// 1. Deploy updated firestore.indexes.json: `firebase deploy --only firestore:indexes`
/// 2. Wait for index build completion (check Firebase Console > Firestore > Indexes)
/// 3. Monitor app logs for successful query execution (no index errors)
///
/// **DEBUGGING:**
/// All query methods now include detailed logging that prints:
/// - Exact collection name
/// - All where() filters applied
/// - All orderBy() sorts applied  
/// - Whether a composite index is required
/// Check console logs at runtime to verify exact queries being executed.
/// ============================================================================
class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Verify user is authenticated before executing Firestore operations
  /// 
  /// Throws [FirebaseAuthException] with code 'unauthenticated' if user is not signed in
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access expense data',
      );
    }
  }

  // Create expense
  Future<String> createExpense({
    required double amount,
    required String category,
    required String description,
    required DateTime date,
    String? driverId,
    String? loadId,
    String? receiptUrl,
    required String createdBy,
  }) async {
    _requireAuth();
    final docRef = await _db.collection('expenses').add({
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      if (driverId != null) 'driverId': driverId,
      if (loadId != null) 'loadId': loadId,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Stream all expenses
  Stream<List<Expense>> streamAllExpenses() {
    _requireAuth();
    
    // QUERY ANALYSIS: This query only uses orderBy, no composite index needed
    // Query: collection('expenses').orderBy('date', descending: true)
    // Index requirement: Single-field index on 'date' (auto-created by Firestore)
    print('[ExpenseService] Executing query: streamAllExpenses()');
    print('  Collection: expenses');
    print('  OrderBy: date DESC');
    print('  Index required: Single-field (auto-created)');
    
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('[ExpenseService] streamAllExpenses() returned ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();
        });
  }

  // Stream expenses by driver
  Stream<List<Expense>> streamDriverExpenses(String driverId) {
    _requireAuth();
    
    // 🔴 COMPOSITE INDEX REQUIRED - This query WILL FAIL without proper index
    // Query: collection('expenses').where('driverId', ==).orderBy('date', descending: true)
    // 
    // Required composite index:
    // {
    //   "collectionGroup": "expenses",
    //   "queryScope": "COLLECTION",
    //   "fields": [
    //     {"fieldPath": "driverId", "order": "ASCENDING"},
    //     {"fieldPath": "date", "order": "DESCENDING"}
    //   ]
    // }
    //
    // ISSUE: This index does NOT exist in firestore.indexes.json
    // ERROR: User will see "The query requires an index" error
    print('[ExpenseService] Executing query: streamDriverExpenses(driverId: $driverId)');
    print('  Collection: expenses');
    print('  Where: driverId == $driverId');
    print('  OrderBy: date DESC');
    print('  ⚠️  REQUIRES COMPOSITE INDEX: driverId ASC + date DESC');
    
    return _db
        .collection('expenses')
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('[ExpenseService] streamDriverExpenses() returned ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();
        });
  }

  // Stream expenses by load
  Stream<List<Expense>> streamLoadExpenses(String loadId) {
    _requireAuth();
    
    // 🔴 COMPOSITE INDEX REQUIRED - This query WILL FAIL without proper index
    // Query: collection('expenses').where('loadId', ==).orderBy('date', descending: true)
    // 
    // Required composite index:
    // {
    //   "collectionGroup": "expenses",
    //   "queryScope": "COLLECTION",
    //   "fields": [
    //     {"fieldPath": "loadId", "order": "ASCENDING"},
    //     {"fieldPath": "date", "order": "DESCENDING"}
    //   ]
    // }
    //
    // ISSUE: This index does NOT exist in firestore.indexes.json
    // ERROR: User will see "The query requires an index" error
    print('[ExpenseService] Executing query: streamLoadExpenses(loadId: $loadId)');
    print('  Collection: expenses');
    print('  Where: loadId == $loadId');
    print('  OrderBy: date DESC');
    print('  ⚠️  REQUIRES COMPOSITE INDEX: loadId ASC + date DESC');
    
    return _db
        .collection('expenses')
        .where('loadId', isEqualTo: loadId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('[ExpenseService] streamLoadExpenses() returned ${snapshot.docs.length} documents');
          return snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();
        });
  }

  // Get total expenses by driver
  Future<double> getDriverTotalExpenses(String driverId) async {
    _requireAuth();
    final snapshot = await _db
        .collection('expenses')
        .where('driverId', isEqualTo: driverId)
        .get();
    
    return snapshot.docs.fold<double>(
        0.0, (sum, doc) => sum + ((doc.data()['amount'] ?? 0) as num).toDouble());
  }

  // Get total expenses by category
  Future<Map<String, double>> getExpensesByCategory({
    String? driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _requireAuth();
    
    // QUERY ANALYSIS: This method builds dynamic queries with multiple filters
    // Depending on parameters, different composite indexes may be required
    print('[ExpenseService] Executing query: getExpensesByCategory()');
    print('  Collection: expenses');
    
    Query query = _db.collection('expenses');
    
    if (driverId != null) {
      // 🔴 COMPOSITE INDEX REQUIRED when combined with date filters
      // Query: where('driverId', ==) + where('date', >=) and/or where('date', <=)
      // 
      // Required composite index:
      // {
      //   "collectionGroup": "expenses",
      //   "queryScope": "COLLECTION",
      //   "fields": [
      //     {"fieldPath": "driverId", "order": "ASCENDING"},
      //     {"fieldPath": "date", "order": "ASCENDING"}
      //   ]
      // }
      print('  Where: driverId == $driverId');
      query = query.where('driverId', isEqualTo: driverId);
    }
    if (startDate != null) {
      print('  Where: date >= $startDate');
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      print('  Where: date <= $endDate');
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    if (driverId != null && (startDate != null || endDate != null)) {
      print('  ⚠️  REQUIRES COMPOSITE INDEX: driverId ASC + date ASC');
    } else if (startDate != null && endDate != null) {
      print('  ⚠️  Date range queries on same field are allowed (uses single-field index)');
    }
    
    final snapshot = await query.get();
    print('[ExpenseService] getExpensesByCategory() returned ${snapshot.docs.length} documents');
    
    final Map<String, double> categoryTotals = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String;
      final amount = ((data['amount'] ?? 0) as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    
    return categoryTotals;
  }

  // Update expense
  Future<void> updateExpense({
    required String expenseId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? receiptUrl,
  }) async {
    _requireAuth();
    final Map<String, dynamic> updates = {};
    if (amount != null) updates['amount'] = amount;
    if (category != null) updates['category'] = category;
    if (description != null) updates['description'] = description;
    if (date != null) updates['date'] = Timestamp.fromDate(date);
    if (receiptUrl != null) updates['receiptUrl'] = receiptUrl;
    
    if (updates.isNotEmpty) {
      await _db.collection('expenses').doc(expenseId).update(updates);
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    _requireAuth();
    await _db.collection('expenses').doc(expenseId).delete();
  }
}
