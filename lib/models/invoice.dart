import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceLineItem {
  final String description;
  final double quantity;
  final double rate;
  
  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.rate,
  });
  
  double get amount => quantity * rate;
  
  Map<String, dynamic> toMap() => {
    'description': description,
    'quantity': quantity,
    'rate': rate,
  };
  
  static InvoiceLineItem fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      rate: (map['rate'] ?? 0).toDouble(),
    );
  }
}

class PaymentDetail {
  final DateTime date;
  final double amount;
  final String method;
  final String? reference;
  
  PaymentDetail({
    required this.date,
    required this.amount,
    required this.method,
    this.reference,
  });
  
  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'amount': amount,
    'method': method,
    if (reference != null) 'reference': reference,
  };
  
  static PaymentDetail fromMap(Map<String, dynamic> map) {
    return PaymentDetail(
      date: DateTime.parse(map['date'] as String),
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] as String? ?? '',
      reference: map['reference'] as String?,
    );
  }
}

class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String? loadId;
  final String customerName;
  final String customerAddress;
  final List<InvoiceLineItem> lineItems;
  final double taxRate;
  final String status; // 'draft', 'sent', 'paid', 'overdue'
  final List<PaymentDetail> payments;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  
  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    this.loadId,
    required this.customerName,
    required this.customerAddress,
    required this.lineItems,
    this.taxRate = 0.0,
    required this.status,
    this.payments = const [],
    this.notes,
    required this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  double get subtotal => lineItems.fold(0.0, (sum, item) => sum + item.amount);
  
  double get tax => subtotal * taxRate;
  
  double get total => subtotal + tax;
  
  double get amountPaid => payments.fold(0.0, (sum, payment) => sum + payment.amount);
  
  double get balance => total - amountPaid;
  
  bool get isPaid => balance <= 0.0;
  
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);
  
  Map<String, dynamic> toMap() => {
    'invoiceNumber': invoiceNumber,
    'invoiceDate': invoiceDate.toIso8601String(),
    'dueDate': dueDate.toIso8601String(),
    if (loadId != null) 'loadId': loadId,
    'customerName': customerName,
    'customerAddress': customerAddress,
    'lineItems': lineItems.map((item) => item.toMap()).toList(),
    'taxRate': taxRate,
    'status': status,
    'payments': payments.map((payment) => payment.toMap()).toList(),
    if (notes != null) 'notes': notes,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
  };
  
  static Invoice fromDoc(DocumentSnapshot doc) {
    return fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
  
  static Invoice fromMap(String id, Map<String, dynamic> map) {
    return Invoice(
      id: id,
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      invoiceDate: DateTime.parse(map['invoiceDate'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      loadId: map['loadId'] as String?,
      customerName: map['customerName'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      lineItems: (map['lineItems'] as List<dynamic>?)
          ?.map((item) => InvoiceLineItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      status: map['status'] as String? ?? 'draft',
      payments: (map['payments'] as List<dynamic>?)
          ?.map((payment) => PaymentDetail.fromMap(payment as Map<String, dynamic>))
          .toList() ?? [],
      notes: map['notes'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
  
  Invoice copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    String? loadId,
    String? customerName,
    String? customerAddress,
    List<InvoiceLineItem>? lineItems,
    double? taxRate,
    String? status,
    List<PaymentDetail>? payments,
    String? notes,
  }) {
    return Invoice(
      id: id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      loadId: loadId ?? this.loadId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      lineItems: lineItems ?? this.lineItems,
      taxRate: taxRate ?? this.taxRate,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
