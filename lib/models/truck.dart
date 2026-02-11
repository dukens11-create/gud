import 'package:cloud_firestore/cloud_firestore.dart';

/// Truck model representing a vehicle in the fleet
class Truck {
  final String id;
  final String truckNumber;
  final String vin;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String status; // 'available', 'in_use', 'maintenance', 'inactive'
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Truck({
    required this.id,
    required this.truckNumber,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert truck to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'truckNumber': truckNumber,
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'status': status,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create truck from Firestore document
  static Truck fromMap(String id, Map<String, dynamic> data) {
    return Truck(
      id: id,
      truckNumber: data['truckNumber'] as String? ?? '',
      vin: data['vin'] as String? ?? '',
      make: data['make'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int? ?? DateTime.now().year,
      plateNumber: data['plateNumber'] as String? ?? '',
      status: data['status'] as String? ?? 'available',
      assignedDriverId: data['assignedDriverId'] as String?,
      assignedDriverName: data['assignedDriverName'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create a copy of truck with updated fields
  Truck copyWith({
    String? id,
    String? truckNumber,
    String? vin,
    String? make,
    String? model,
    int? year,
    String? plateNumber,
    String? status,
    String? assignedDriverId,
    String? assignedDriverName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Truck(
      id: id ?? this.id,
      truckNumber: truckNumber ?? this.truckNumber,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      status: status ?? this.status,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if truck is available for assignment
  bool get isAvailable => status == 'available';

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case 'available':
        return 'Available';
      case 'in_use':
        return 'In Use';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  /// Get truck display info (make, model, year)
  String get displayInfo => '$make $model ($year)';

  /// Get full display name with truck number and info
  String get fullDisplayName => '$truckNumber - $displayInfo';
}
