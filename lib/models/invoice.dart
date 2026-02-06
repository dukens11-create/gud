import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an invoice
enum InvoiceStatus {
  draft,
  sent,
  paid,
}

/// Represents a line item in an invoice
class InvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'amount': amount,
    };
  }

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

/// Represents company or client information
class CompanyInfo {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String? phone;
  final String? email;

  CompanyInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'phone': phone,
      'email': email,
    };
  }

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zip: map['zip'] ?? '',
      phone: map['phone'],
      email: map['email'],
    );
  }
}

/// Represents an invoice for a load
class Invoice {
  final String? id;
  final String? loadId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final CompanyInfo companyInfo;
  final CompanyInfo clientInfo;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double tax;
  final double total;
  final String? notes;
  final InvoiceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Invoice({
    this.id,
    this.loadId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.companyInfo,
    required this.clientInfo,
    required this.lineItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.notes,
    this.status = InvoiceStatus.draft,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate total from line items and tax rate
  static double calculateSubtotal(List<InvoiceLineItem> lineItems) {
    return lineItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculate tax from subtotal and tax rate
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }

  /// Calculate total from subtotal and tax
  static double calculateTotal(double subtotal, double tax) {
    return subtotal + tax;
  }

  /// Create a copy with updated fields
  Invoice copyWith({
    String? id,
    String? loadId,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    CompanyInfo? companyInfo,
    CompanyInfo? clientInfo,
    List<InvoiceLineItem>? lineItems,
    double? subtotal,
    double? tax,
    double? total,
    String? notes,
    InvoiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      loadId: loadId ?? this.loadId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      companyInfo: companyInfo ?? this.companyInfo,
      clientInfo: clientInfo ?? this.clientInfo,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert invoice to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'loadId': loadId,
      'invoiceNumber': invoiceNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'companyInfo': companyInfo.toMap(),
      'clientInfo': clientInfo.toMap(),
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'notes': notes,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Create invoice from Firestore map
  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      loadId: map['loadId'],
      invoiceNumber: map['invoiceNumber'] ?? '',
      issueDate: (map['issueDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      companyInfo: CompanyInfo.fromMap(map['companyInfo'] ?? {}),
      clientInfo: CompanyInfo.fromMap(map['clientInfo'] ?? {}),
      lineItems: (map['lineItems'] as List<dynamic>?)
              ?.map((item) => InvoiceLineItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      notes: map['notes'],
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
