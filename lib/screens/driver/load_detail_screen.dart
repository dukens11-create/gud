import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../services/mock_data_service.dart';
import '../../services/firestore_service.dart';
import '../../services/navigation_service.dart';
import 'upload_pod_screen.dart';
import 'upload_bol_screen.dart';

class LoadDetailScreen extends StatefulWidget {
  final LoadModel load;

  const LoadDetailScreen({super.key, required this.load});

  @override
  State<LoadDetailScreen> createState() => _LoadDetailScreenState();
}

class _LoadDetailScreenState extends State<LoadDetailScreen> {
  late LoadModel _currentLoad;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentLoad = widget.load;
  }

  Future<void> _refreshLoadData() async {
    setState(() => _isRefreshing = true);
    
    try {
      final firestoreService = FirestoreService();
      final updatedLoad = await firestoreService.getLoad(widget.load.id);
      if (updatedLoad != null && mounted) {
        setState(() => _currentLoad = updatedLoad);
      }
    } catch (e) {
      if (mounted) {
        NavigationService.showError('Failed to refresh load data');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();
    final firestoreService = FirestoreService();
    final currentUserId = mockService.currentUserId ?? '';
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final load = _currentLoad;

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

            // BOL Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill of Lading (BOL)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (load.bolPhotoUrl != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (load.bolPhotoUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          load.bolPhotoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (load.bolUploadedAt != null)
                        Text(
                          'Uploaded: ${dateFormat.format(load.bolUploadedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UploadBOLScreen(load: load),
                                ),
                              );
                              if (result == true) {
                                // Refresh load data to show newly uploaded photo
                                await _refreshLoadData();
                              }
                            },
                            icon: Icon(load.bolPhotoUrl == null ? Icons.camera_alt : Icons.refresh),
                            label: Text(load.bolPhotoUrl == null ? 'Upload BOL' : 'Update BOL'),
                          ),
                        ),
                        if (load.bolPhotoUrl != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _viewFullPhoto(context, load.bolPhotoUrl!),
                            icon: const Icon(Icons.fullscreen),
                            tooltip: 'View Full Size',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // POD Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Proof of Delivery (POD)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (load.podPhotoUrl != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (load.podPhotoUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          load.podPhotoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (load.podUploadedAt != null)
                        Text(
                          'Uploaded: ${dateFormat.format(load.podUploadedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (load.status == 'delivered' || load.status == 'in_transit')
                                ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UploadPODScreen(load: load),
                                      ),
                                    );
                                    if (result == true) {
                                      // Refresh load data to show newly uploaded photo
                                      await _refreshLoadData();
                                    }
                                  }
                                : null,
                            icon: Icon(load.podPhotoUrl == null ? Icons.camera_alt : Icons.refresh),
                            label: Text(load.podPhotoUrl == null ? 'Upload POD' : 'Update POD'),
                          ),
                        ),
                        if (load.podPhotoUrl != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _viewFullPhoto(context, load.podPhotoUrl!),
                            icon: const Icon(Icons.fullscreen),
                            tooltip: 'View Full Size',
                          ),
                        ],
                      ],
                    ),
                    if (load.status != 'delivered' && load.status != 'in_transit')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'POD can be uploaded after starting trip',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
                        onPressed: () => _showAcceptDialog(load, firestoreService),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Accept This Load'),
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
                        onPressed: () => _showDeclineDialog(load, firestoreService),
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
                  if (_canShowTripButtons(load.status)) ...[
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
        return Colors.orange.shade600; // Yellow/Orange (awaiting action)
      case 'accepted':
        return Colors.lightBlue.shade600; // Light Blue (ready to start)
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue.shade700; // Blue (in progress)
      case 'delivered':
        return Colors.green.shade700; // Green (completed)
      case 'declined':
        return Colors.red.shade600; // Red (rejected)
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

  /// Check if trip management buttons should be shown for this load status
  bool _canShowTripButtons(String status) {
    return status == 'accepted' || 
           status == 'assigned' || 
           status == 'picked_up' || 
           status == 'in_transit';
  }

  /// View full photo in a modal viewer
  void _viewFullPhoto(BuildContext context, String photoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('View Photo'),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(photoUrl),
            ),
          ),
        ),
      ),
    );
  }

  /// Show accept load confirmation dialog
  Future<void> _showAcceptDialog(LoadModel load, FirestoreService firestoreService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Load?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Load: ${load.loadNumber}'),
            const SizedBox(height: 8),
            Text('Destination: ${load.deliveryAddress}'),
            const SizedBox(height: 16),
            const Text(
              'Once accepted, you\'ll need to complete this delivery.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await firestoreService.acceptLoad(load.id);
        if (mounted) {
          await _refreshLoadData();
          NavigationService.showSuccess('Load accepted! Tap "Start Trip" when ready.');
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error accepting load: $e');
        }
      }
    }
  }

  /// Show decline load dialog with optional reason field
  Future<void> _showDeclineDialog(LoadModel load, FirestoreService firestoreService) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Load?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for declining (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Schedule conflict, truck maintenance, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline Load'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await firestoreService.declineLoad(
          load.id,
          reason: reasonController.text.trim(),
        );
        if (mounted) {
          NavigationService.showSuccess('Load declined. Admin has been notified.');
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error declining load: $e');
        }
      }
    }
    
    reasonController.dispose();
  }
}
