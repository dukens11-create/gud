import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/invoice.dart';

/// Invoice Service - Manages invoice operations
/// 
/// Handles:
/// - Creating invoices
/// - Updating invoice status
/// - Querying invoices by status
/// - Generating invoice numbers
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  static InvoiceService get instance => _instance;
  InvoiceService._internal();
  
  /// Verify user is authenticated before executing Firestore operations
  /// 
  /// Throws [FirebaseAuthException] with code 'unauthenticated' if user is not signed in
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access invoice data',
      );
    }
  }

  /// Create a new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    _requireAuth();
    final docRef = _firestore.collection('invoices').doc();
    final invoiceWithId = invoice.copyWith(
      id: docRef.id,
      invoiceNumber: await _generateInvoiceNumber(),
    );
    await docRef.set(invoiceWithId.toMap());
    return invoiceWithId;
  }

  /// Update invoice status
  Future<void> updateStatus(String invoiceId, String status) async {
    _requireAuth();
    await _firestore.collection('invoices').doc(invoiceId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream invoices by status
  Stream<List<Invoice>> streamInvoicesByStatus(String status) {
    _requireAuth();
    var query = _firestore.collection('invoices').orderBy('createdAt', descending: true);
    
    if (status != 'all') {
      query = query.where('status', isEqualTo: status) as Query<Map<String, dynamic>>;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Invoice.fromMap(doc.data());
      }).toList();
    });
  }

  /// Get invoice by ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    _requireAuth();
    final doc = await _firestore.collection('invoices').doc(invoiceId).get();
    if (!doc.exists) return null;
    return Invoice.fromMap(doc.data()!);
  }

  /// Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    _requireAuth();
    await _firestore.collection('invoices').doc(invoiceId).delete();
  }

  /// Generate unique invoice number
  Future<String> _generateInvoiceNumber() async {
    _requireAuth();
    // Get the count of existing invoices
    final snapshot = await _firestore.collection('invoices').get();
    final count = snapshot.docs.length + 1;
    
    // Format: INV-YYYY-XXXX
    final year = DateTime.now().year;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Search invoices
  Future<List<Invoice>> searchInvoices(String query) async {
    _requireAuth();
    // Note: This is a simple implementation. For production, consider using
    // a dedicated search service like Algolia or Elasticsearch
    final snapshot = await _firestore.collection('invoices').get();
    
    final allInvoices = snapshot.docs.map((doc) {
      return Invoice.fromMap(doc.data());
    }).toList();

    // Filter by invoice number or client name
    final searchQuery = query.toLowerCase();
    return allInvoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(searchQuery) ||
             invoice.clientInfo.name.toLowerCase().contains(searchQuery);
    }).toList();
  }

  /// Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _requireAuth();
    // Note: This query uses range filters which work well for date ranges
    // A composite index may be required in Firestore for optimal performance
    final snapshot = await _firestore
        .collection('invoices')
        .where('issueDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('issueDate', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      return Invoice.fromMap(doc.data());
    }).toList();
  }

  /// Calculate total paid this month
  Future<double> getTotalPaidThisMonth() async {
    _requireAuth();
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // Note: This query combines equality and range filters
    // A composite index is required in Firestore: (status ASC, updatedAt ASC)
    final snapshot = await _firestore
        .collection('invoices')
        .where('status', isEqualTo: 'paid')
        .where('updatedAt', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('updatedAt', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      final invoice = Invoice.fromMap(doc.data());
      total += invoice.total;
    }

    return total;
  }
}
