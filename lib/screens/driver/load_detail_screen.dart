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
  bool _isLoading = false;

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
                  // For pending status - show Accept button with info card
                  if (load.status == 'pending') ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This load is pending. Accept it to start your trip.',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptLoad(),
                        icon: const Icon(Icons.check_circle_outline, size: 28),
                        label: const Text('Accept This Load', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ]
                  // For accepted status - show Start Trip button
                  else if (load.status == 'accepted') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startTrip(),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('Start Trip', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ]
                  // For in_transit status - show Mark Delivered button
                  else if (load.status == 'in_transit') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markDelivered(),
                        icon: const Icon(Icons.check_circle, size: 28),
                        label: const Text('Mark as Delivered', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ]
                  // For assigned status (legacy) - show Mark as Picked Up and Start Trip  
                  else if (load.status == 'assigned') ...[
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
                  ]
                  // For picked_up status (legacy) - show Start Trip
                  else if (load.status == 'picked_up') ...[
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
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptLoad() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Load?'),
        content: const Text('Once accepted, you can start the trip when ready.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      
      await firestoreService.acceptLoad(widget.load.id);

      // Refresh the load data to reflect the new status
      await _refreshLoadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load accepted! You can now start the trip.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startTrip() async {
    try {
      setState(() => _isLoading = true);
      
      await firestoreService.startTrip(widget.load.id);

      // Refresh the load data to reflect the new status
      await _refreshLoadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markDelivered() async {
    try {
      setState(() => _isLoading = true);
      
      await firestoreService.markLoadAsDelivered(widget.load.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Load marked as delivered!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        return Colors.orange;  // Awaiting driver acceptance
      case 'accepted':
        return Colors.lightBlue;  // Accepted, ready to start
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.blue;  // Trip in progress
      case 'delivered':
        return Colors.green;  // Delivery completed
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
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
}
