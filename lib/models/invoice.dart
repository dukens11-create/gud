import '../utils/datetime_utils.dart';

/// Invoice Model
/// 
/// Represents an invoice with line items, client info, and payment details
class Invoice {
  final String id;
  final String loadId;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final CompanyInfo companyInfo;
  final ClientInfo clientInfo;
  final List<LineItem> lineItems;
  final double subtotal;
  final double tax;
  final double total;
  final String notes;
  final String status; // draft, sent, paid
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.loadId,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.companyInfo,
    required this.clientInfo,
    required this.lineItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loadId': loadId,
      'invoiceNumber': invoiceNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'companyInfo': companyInfo.toMap(),
      'clientInfo': clientInfo.toMap(),
      'lineItems': lineItems.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'notes': notes,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      loadId: map['loadId'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      issueDate: DateTimeUtils.parseDateTime(map['issueDate']) ?? DateTime.now(),
      dueDate: DateTimeUtils.parseDateTime(map['dueDate']) ?? DateTime.now(),
      companyInfo: CompanyInfo.fromMap(map['companyInfo'] as Map<String, dynamic>),
      clientInfo: ClientInfo.fromMap(map['clientInfo'] as Map<String, dynamic>),
      lineItems: (map['lineItems'] as List)
          .map((item) => LineItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String,
      status: map['status'] as String,
      createdAt: DateTimeUtils.parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DateTimeUtils.parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Invoice copyWith({
    String? id,
    String? loadId,
    String? invoiceNumber,
    DateTime? issueDate,
    DateTime? dueDate,
    CompanyInfo? companyInfo,
    ClientInfo? clientInfo,
    List<LineItem>? lineItems,
    double? subtotal,
    double? tax,
    double? total,
    String? notes,
    String? status,
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
}

/// Company Information for invoices
class CompanyInfo {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String email;
  final String? logo;

  CompanyInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
    this.logo,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
      'logo': logo,
    };
  }

  factory CompanyInfo.fromMap(Map<String, dynamic> map) {
    return CompanyInfo(
      name: map['name'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zipCode: map['zipCode'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      logo: map['logo'] as String?,
    );
  }
}

/// Client Information for invoices
class ClientInfo {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String email;

  ClientInfo({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'phone': phone,
      'email': email,
    };
  }

  factory ClientInfo.fromMap(Map<String, dynamic> map) {
    return ClientInfo(
      name: map['name'] as String,
      address: map['address'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zipCode: map['zipCode'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
    );
  }
}

/// Invoice Line Item
class LineItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  LineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}
