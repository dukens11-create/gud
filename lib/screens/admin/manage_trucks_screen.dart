import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/truck.dart';
import '../../services/truck_service.dart';
import '../../services/navigation_service.dart';

/// Manage Trucks Screen - Comprehensive truck management functionality
/// 
/// Features:
/// - List view with status badges
/// - Search and filter
/// - Add/Edit trucks
/// - Soft delete with confirmation
/// - View assigned driver
class ManageTrucksScreen extends StatefulWidget {
    // ...rest of the file content up to line 782 with the fixed NavigationService calls...
    NavigationService.showSuccess('Truck added successfully');
    // ...
    NavigationService.showSuccess('Truck updated successfully');
    // ...
    NavigationService.showError('Error: $e');
    // ...
    NavigationService.showSuccess('Truck deleted successfully');
    // ...
    NavigationService.showError('Error deleting truck: $e');
    // ...
}