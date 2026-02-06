import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';

/// Service for managing invoices
class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for invoices
  CollectionReference<Map<String, dynamic>> get _invoicesCollection =>
      _firestore.collection('invoices');

  /// Generate a unique invoice number
  /// Format: INV-YYYYMMDD-XXXX (where XXXX is a sequential number)
  Future<String> generateInvoiceNumber() async {
    try {
      final now = DateTime.now();
      final datePrefix =
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // Query for invoices with the same date prefix
      final snapshot = await _invoicesCollection
          .where('invoiceNumber', isGreaterThanOrEqualTo: datePrefix)
          .where('invoiceNumber', isLessThan: '${datePrefix}Z')
          .orderBy('invoiceNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return '$datePrefix-0001';
      }

      // Extract the last sequence number and increment
      final lastInvoiceNumber = snapshot.docs.first.data()['invoiceNumber'] as String;
      final lastSequence = int.parse(lastInvoiceNumber.split('-').last);
      final nextSequence = (lastSequence + 1).toString().padLeft(4, '0');

      return '$datePrefix-$nextSequence';
    } catch (e) {
      // Fallback to timestamp-based number if query fails
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'INV-$timestamp';
    }
  }

  /// Create a new invoice
  Future<String> createInvoice(Invoice invoice) async {
    try {
      // Generate invoice number if not provided
      String invoiceNumber = invoice.invoiceNumber;
      if (invoiceNumber.isEmpty) {
        invoiceNumber = await generateInvoiceNumber();
      }

      final invoiceWithNumber = invoice.copyWith(
        invoiceNumber: invoiceNumber,
        createdAt: DateTime.now(),
      );

      final docRef = await _invoicesCollection.add(invoiceWithNumber.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }

  /// Get invoice by ID
  Future<Invoice?> getInvoice(String id) async {
    try {
      final doc = await _invoicesCollection.doc(id).get();
      if (!doc.exists) return null;
      return Invoice.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  /// Update an existing invoice
  Future<void> updateInvoice(String id, Invoice invoice) async {
    try {
      final updatedInvoice = invoice.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );
      await _invoicesCollection.doc(id).update(updatedInvoice.toMap());
    } catch (e) {
      throw Exception('Failed to update invoice: $e');
    }
  }

  /// Delete an invoice
  Future<void> deleteInvoice(String id) async {
    try {
      await _invoicesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }

  /// Stream all invoices
  Stream<List<Invoice>> streamInvoices() {
    return _invoicesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream invoices by status
  Stream<List<Invoice>> streamInvoicesByStatus(InvoiceStatus status) {
    return _invoicesCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream invoices for a specific load
  Stream<List<Invoice>> streamInvoicesByLoad(String loadId) {
    return _invoicesCollection
        .where('loadId', isEqualTo: loadId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Invoice.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get invoices by status (one-time fetch)
  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    try {
      final snapshot = await _invoicesCollection
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invoices by status: $e');
    }
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String id, InvoiceStatus status) async {
    try {
      await _invoicesCollection.doc(id).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update invoice status: $e');
    }
  }

  /// Mark invoice as sent
  Future<void> markAsSent(String id) async {
    await updateInvoiceStatus(id, InvoiceStatus.sent);
  }

  /// Mark invoice as paid
  Future<void> markAsPaid(String id) async {
    await updateInvoiceStatus(id, InvoiceStatus.paid);
  }

  /// Calculate totals for invoices by status
  Future<Map<String, double>> calculateTotalsByStatus() async {
    try {
      final allInvoices = await _invoicesCollection.get();
      
      double draftTotal = 0.0;
      double sentTotal = 0.0;
      double paidTotal = 0.0;

      for (var doc in allInvoices.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final total = (data['total'] ?? 0).toDouble();

        switch (status) {
          case 'draft':
            draftTotal += total;
            break;
          case 'sent':
            sentTotal += total;
            break;
          case 'paid':
            paidTotal += total;
            break;
        }
      }

      return {
        'draft': draftTotal,
        'sent': sentTotal,
        'paid': paidTotal,
        'total': draftTotal + sentTotal + paidTotal,
      };
    } catch (e) {
      throw Exception('Failed to calculate totals: $e');
    }
  }

  /// Search invoices by invoice number or client name
  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Search by invoice number (exact match or starts with)
      final snapshot = await _invoicesCollection
          .where('invoiceNumber', isGreaterThanOrEqualTo: query.toUpperCase())
          .where('invoiceNumber', isLessThan: '${query.toUpperCase()}Z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to search invoices: $e');
    }
  }

  /// Get invoices within a date range
  Future<List<Invoice>> getInvoicesByDateRange(
      DateTime start, DateTime end) async {
    try {
      final snapshot = await _invoicesCollection
          .where('issueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('issueDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('issueDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invoices by date range: $e');
    }
  }
}
