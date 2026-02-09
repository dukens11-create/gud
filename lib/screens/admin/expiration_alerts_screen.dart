import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/driver_extended.dart';
import '../../services/driver_extended_service.dart';

/// Expiration Alerts Screen
/// 
/// Displays all document expiration alerts for admin review with:
/// - Critical alerts (< 7 days) in red
/// - Warning alerts (7-30 days) in yellow
/// - Sortable/filterable list
/// - Document type, driver/truck info, expiration date, days remaining
class ExpirationAlertsScreen extends StatefulWidget {
  const ExpirationAlertsScreen({Key? key}) : super(key: key);

  @override
  State<ExpirationAlertsScreen> createState() => _ExpirationAlertsScreenState();
}

class _ExpirationAlertsScreenState extends State<ExpirationAlertsScreen> {
  final DriverExtendedService _driverService = DriverExtendedService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  
  String _filterType = 'all';
  String _sortBy = 'days'; // days, type, date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Expiration Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ExpirationAlert>>(
        stream: _driverService.streamExpirationAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No expiring documents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All documents are up to date',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          List<ExpirationAlert> alerts = snapshot.data!;
          
          // Apply filter
          if (_filterType != 'all') {
            alerts = alerts
                .where((alert) => alert.type.value == _filterType)
                .toList();
          }
          
          // Apply sort
          if (_sortBy == 'days') {
            alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
          } else if (_sortBy == 'type') {
            alerts.sort((a, b) =>
                a.type.displayName.compareTo(b.type.displayName));
          } else if (_sortBy == 'date') {
            alerts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          }

          final criticalAlerts =
              alerts.where((alert) => alert.isCritical).length;
          final warningAlerts = alerts.length - criticalAlerts;

          return Column(
            children: [
              _buildSummaryCard(criticalAlerts, warningAlerts),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertCard(alerts[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(int criticalCount, int warningCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.error,
              label: 'Critical',
              count: criticalCount,
              color: Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.warning,
              label: 'Warning',
              count: warningCount,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(ExpirationAlert alert) {
    final color = alert.isCritical ? Colors.red : Colors.orange;
    final icon = _getIconForAlertType(alert.type);

    return FutureBuilder<Map<String, String>>(
      future: _getAlertDetails(alert),
      builder: (context, snapshot) {
        final details = snapshot.data ?? {};
        final name = details['name'] ?? 'Loading...';
        final identifier = details['identifier'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Alert icon with color indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                
                // Alert details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.type.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (identifier.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          identifier,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Expires: ${_dateFormat.format(alert.expiryDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Days remaining badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        alert.daysRemaining.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'DAYS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForAlertType(ExpirationAlertType type) {
    switch (type) {
      case ExpirationAlertType.driverLicense:
        return Icons.badge;
      case ExpirationAlertType.medicalCard:
        return Icons.medical_services;
      case ExpirationAlertType.truckRegistration:
        return Icons.app_registration;
      case ExpirationAlertType.truckInsurance:
        return Icons.shield;
      case ExpirationAlertType.certification:
        return Icons.card_membership;
      default:
        return Icons.description;
    }
  }

  Future<Map<String, String>> _getAlertDetails(ExpirationAlert alert) async {
    if (alert.driverId != null) {
      try {
        final driverDoc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(alert.driverId)
            .get();
        
        if (driverDoc.exists) {
          final data = driverDoc.data()!;
          return {
            'name': data['name'] ?? 'Unknown Driver',
            'identifier': 'Driver',
          };
        }
      } catch (e) {
        print('Error fetching driver details: $e');
      }
    }
    
    if (alert.truckNumber != null) {
      return {
        'name': 'Truck ${alert.truckNumber}',
        'identifier': 'Vehicle',
      };
    }
    
    return {
      'name': 'Unknown',
      'identifier': '',
    };
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All Documents', 'all'),
            _buildFilterOption('Driver License', 'driver_license'),
            _buildFilterOption('Medical Card', 'medical_card'),
            _buildFilterOption('Truck Registration', 'truck_registration'),
            _buildFilterOption('Truck Insurance', 'truck_insurance'),
            _buildFilterOption('Certification', 'certification'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _filterType,
      onChanged: (val) {
        setState(() {
          _filterType = val!;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('Days Remaining', 'days'),
            _buildSortOption('Document Type', 'type'),
            _buildSortOption('Expiration Date', 'date'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _sortBy,
      onChanged: (val) {
        setState(() {
          _sortBy = val!;
        });
        Navigator.pop(context);
      },
    );
  }
}
