import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../services/mock_data_service.dart';
import '../../services/firestore_service.dart';
import '../../services/navigation_service.dart';
import 'upload_pod_screen.dart';

class LoadDetailScreen extends StatelessWidget {
  final LoadModel load;

  const LoadDetailScreen({super.key, required this.load});

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();
    final firestoreService = FirestoreService();
    final currentUserId = mockService.currentUserId ?? '';
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(load.loadNumber.isNotEmpty ? load.loadNumber : 'Load Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Chip(
                          label: Text(
                            _getStatusLabel(load.status),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(load.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Load Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Load Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Load Number', load.loadNumber.isNotEmpty ? load.loadNumber : 'Unknown'),
                    if (load.driverName != null && load.driverName!.isNotEmpty)
                      _buildDetailRow('Driver', load.driverName!),
                    _buildDetailRow('Rate', '\$${load.rate.toStringAsFixed(2)}'),
                    if (load.miles > 0)
                      _buildDetailRow('Miles', '${load.miles.toStringAsFixed(1)} mi'),
                    if (load.notes != null && load.notes!.isNotEmpty)
                      _buildDetailRow('Notes', load.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pickup/Delivery Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Locations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(load.pickupAddress.isNotEmpty ? load.pickupAddress : 'Unknown'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(load.deliveryAddress.isNotEmpty ? load.deliveryAddress : 'Unknown'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Timeline',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildTimelineItem(
                      'Created',
                      dateFormat.format(load.createdAt),
                      Icons.add_circle,
                      Colors.blue,
                    ),
                    if (load.pickedUpAt != null)
                      _buildTimelineItem(
                        'Picked Up',
                        dateFormat.format(load.pickedUpAt!),
                        Icons.check_circle,
                        Colors.orange,
                      ),
                    if (load.tripStartAt != null)
                      _buildTimelineItem(
                        'Trip Started',
                        dateFormat.format(load.tripStartAt!),
                        Icons.local_shipping,
                        Colors.purple,
                      ),
                    if (load.deliveredAt != null)
                      _buildTimelineItem(
                        'Delivered',
                        dateFormat.format(load.deliveredAt!),
                        Icons.done_all,
                        Colors.green,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (only for assigned driver and not delivered/declined)
            if (load.driverId == currentUserId && 
                load.status != 'delivered' && 
                load.status != 'declined')
              Column(
                children: [
                  // For pending status - show Accept/Decline buttons
                  if (load.status == 'pending') ...[
                    // Accept Load button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await firestoreService.updateLoadStatus(
                              loadId: load.id,
                              status: 'accepted',
                            );
                            if (context.mounted) {
                              NavigationService.showSuccess('Load accepted successfully');
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              NavigationService.showError('Error accepting load: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Accept Load'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Decline Load button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Decline Load?'),
                              content: const Text(
                                'Are you sure you want to decline this load? Your admin will be notified.',
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text('Decline'),
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true && context.mounted) {
                            try {
                              await firestoreService.updateLoadStatus(
                                loadId: load.id,
                                status: 'declined',
                              );
                              if (context.mounted) {
                                NavigationService.showSuccess('Load declined');
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                NavigationService.showError('Error declining load: $e');
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Decline Load'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                  
                  // For accepted, assigned, picked_up, or in_transit - show workflow buttons
                  if (load.status == 'accepted' || 
                      load.status == 'assigned' || 
                      load.status == 'picked_up' || 
                      load.status == 'in_transit') ...[
                    // Simple one-tap "Delivered" button for quick delivery marking
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await firestoreService.markLoadAsDelivered(load.id);
                            if (context.mounted) {
                              NavigationService.showSuccess('Load marked as delivered');
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              NavigationService.showError('Error marking load as delivered: $e');
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Delivered'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  // Existing detailed workflow buttons
                  if (load.status == 'assigned' || load.status == 'accepted')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await mockService.updateLoadStatus(
                            loadId: load.id,
                            status: 'picked_up',
                            pickedUpAt: DateTime.now(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Load marked as picked up')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Picked Up'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  if (load.status == 'picked_up')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await mockService.updateLoadStatus(
                            loadId: load.id,
                            status: 'in_transit',
                            tripStartAt: DateTime.now(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Trip started')),
                            );
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Start Trip'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  if (load.status == 'in_transit')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UploadPODScreen(load: load),
                                ),
                              );
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Upload Proof of Delivery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Show dialog to enter miles
                              final milesController = TextEditingController();
                              try {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Complete Delivery'),
                                    content: TextField(
                                      controller: milesController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Total Miles',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Complete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  final miles = double.tryParse(milesController.text) ?? 0.0;
                                  await mockService.updateLoadStatus(
                                    loadId: load.id,
                                    status: 'delivered',
                                    deliveredAt: DateTime.now(),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Delivery completed')),
                                    );
                                    Navigator.pop(context);
                                  }
                                }
                              } finally {
                                milesController.dispose();
                              }
                            },
                            icon: const Icon(Icons.done_all),
                            label: const Text('Complete Delivery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green.shade700;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'AWAITING ACCEPTANCE';
      case 'accepted':
        return 'ACCEPTED';
      case 'declined':
        return 'DECLINED';
      case 'assigned':
        return 'ASSIGNED';
      case 'picked_up':
        return 'PICKED UP';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delivered':
        return 'DELIVERED';
      default:
        return status.isNotEmpty ? status.toUpperCase() : 'UNKNOWN';
    }
  }
}
