import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList());
  }

  // Stream expenses by driver
  Stream<List<Expense>> streamDriverExpenses(String driverId) {
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
    await _db.collection('expenses').doc(expenseId).delete();
  }
}
