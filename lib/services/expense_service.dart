import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

/// Expense tracking service for managing business expenses.
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
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
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList());
  }

  // Stream expenses by driver
  Stream<List<Expense>> streamDriverExpenses(String driverId) {
    _requireAuth();
    return _db
        .collection('expenses')
        .where('driverId', isEqualTo: driverId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList());
  }

  // Stream expenses by load
  Stream<List<Expense>> streamLoadExpenses(String loadId) {
    _requireAuth();
    return _db
        .collection('expenses')
        .where('loadId', isEqualTo: loadId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList());
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
    Query query = _db.collection('expenses');
    
    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }
    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    final snapshot = await query.get();
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
