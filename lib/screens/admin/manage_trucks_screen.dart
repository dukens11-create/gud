import 'package:flutter/material.dart';
import 'package:your_project/services/navigation_service.dart';

class ManageTrucksScreen extends StatelessWidget {
  // your existing code

  void addTruck() {
    // your existing code
    NavigationService.showSuccess('Truck added successfully');
    // your existing code
  }

  void updateTruck() {
    // your existing code
    NavigationService.showSuccess('Truck updated successfully');
    // your existing code
  }

  void deleteTruck() {
    // your existing code
    NavigationService.showSuccess('Truck deleted successfully');
    // your existing code
  }

  void handleError(e) {
    NavigationService.showError('Error: $e');
    // your existing code
  }

  // your existing code
}