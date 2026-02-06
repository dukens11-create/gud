import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice.dart';
import '../models/load.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String> _generateInvoiceNumber() async {
    final now = DateTime.now();
    final prefix = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}';
    
    final snapshot = await _firestore
        .collection('invoices')
        .where('invoiceNumber', isGreaterThanOrEqualTo: prefix)
        .where('invoiceNumber', isLessThan: '$prefix\uf8ff')
        .orderBy('invoiceNumber', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return '$prefix-0001';
    }
    
    final lastNumber = snapshot.docs.first.data()['invoiceNumber'] as String;
    final lastSequence = int.parse(lastNumber.split('-').last);
    final nextSequence = (lastSequence + 1).toString().padLeft(4, '0');
    
    return '$prefix-$nextSequence';
  }
  
  Future<Invoice> createInvoice({
    required String customerName,
    required String customerAddress,
    required List<InvoiceLineItem> lineItems,
    required String createdBy,
    String? loadId,
    double taxRate = 0.0,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? notes,
  }) async {
    final invoiceNumber = await _generateInvoiceNumber();
    final now = DateTime.now();
    
    final invoice = Invoice(
      id: '',
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate ?? now,
      dueDate: dueDate ?? now.add(const Duration(days: 30)),
      loadId: loadId,
      customerName: customerName,
      customerAddress: customerAddress,
      lineItems: lineItems,
      taxRate: taxRate,
      status: 'draft',
      createdBy: createdBy,
      notes: notes,
    );
    
    final docRef = await _firestore.collection('invoices').add(invoice.toMap());
    return invoice.copyWith()..id == docRef.id;
  }
  
  Future<Invoice> createInvoiceFromLoad({
    required LoadModel load,
    required String customerName,
    required String customerAddress,
    required String createdBy,
    double taxRate = 0.0,
  }) async {
    final lineItem = InvoiceLineItem(
      description: 'Freight from ${load.pickupAddress} to ${load.deliveryAddress}',
      quantity: load.miles > 0 ? load.miles : 1,
      rate: load.miles > 0 ? (load.rate / load.miles) : load.rate,
    );
    
    return createInvoice(
      customerName: customerName,
      customerAddress: customerAddress,
      lineItems: [lineItem],
      createdBy: createdBy,
      loadId: load.id,
      taxRate: taxRate,
      notes: 'Load #${load.loadNumber}',
    );
  }
  
  Future<void> updateInvoice(String invoiceId, Map<String, dynamic> updates) async {
    await _firestore.collection('invoices').doc(invoiceId).update(updates);
  }
  
  Future<void> markAsPaid({
    required String invoiceId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    final doc = await _firestore.collection('invoices').doc(invoiceId).get();
    if (!doc.exists) throw Exception('Invoice not found');
    
    final invoice = Invoice.fromDoc(doc);
    final payment = PaymentDetail(
      date: DateTime.now(),
      amount: amount,
      method: method,
      reference: reference,
    );
    
    final updatedPayments = [...invoice.payments, payment];
    final newBalance = invoice.total - updatedPayments.fold(0.0, (sum, p) => sum + p.amount);
    
    await updateInvoice(invoiceId, {
      'payments': updatedPayments.map((p) => p.toMap()).toList(),
      'status': newBalance <= 0.0 ? 'paid' : invoice.status,
    });
  }
  
  Future<Invoice?> getInvoice(String invoiceId) async {
    final doc = await _firestore.collection('invoices').doc(invoiceId).get();
    if (!doc.exists) return null;
    return Invoice.fromDoc(doc);
  }
  
  Stream<List<Invoice>> getInvoicesByStatus(String status) {
    return _firestore
        .collection('invoices')
        .where('status', isEqualTo: status)
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromDoc(doc)).toList());
  }
  
  Future<List<Invoice>> getInvoicesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _firestore
        .collection('invoices')
        .where('invoiceDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('invoiceDate', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('invoiceDate', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Invoice.fromDoc(doc)).toList();
  }
  
  Stream<List<Invoice>> getAllInvoices() {
    return _firestore
        .collection('invoices')
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Invoice.fromDoc(doc)).toList());
  }
  
  Future<Map<String, double>> calculateTotals(List<Invoice> invoices) async {
    double totalAmount = 0.0;
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;
    
    for (final invoice in invoices) {
      totalAmount += invoice.total;
      totalPaid += invoice.amountPaid;
      totalOutstanding += invoice.balance;
    }
    
    return {
      'total': totalAmount,
      'paid': totalPaid,
      'outstanding': totalOutstanding,
    };
  }
  
  Future<void> deleteInvoice(String invoiceId) async {
    await _firestore.collection('invoices').doc(invoiceId).delete();
  }
  
  Future<List<Invoice>> searchInvoices(String query) async {
    final snapshot = await _firestore
        .collection('invoices')
        .orderBy('invoiceDate', descending: true)
        .limit(100)
        .get();
    
    final allInvoices = snapshot.docs.map((doc) => Invoice.fromDoc(doc)).toList();
    
    return allInvoices.where((invoice) {
      final searchLower = query.toLowerCase();
      return invoice.invoiceNumber.toLowerCase().contains(searchLower) ||
             invoice.customerName.toLowerCase().contains(searchLower);
    }).toList();
  }
}
