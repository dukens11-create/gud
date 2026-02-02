import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../models/pod.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';

class DriverLoadDetailScreen extends StatefulWidget {
  final LoadModel load;

  const DriverLoadDetailScreen({
    super.key,
    required this.load,
  });

  @override
  State<DriverLoadDetailScreen> createState() => _DriverLoadDetailScreenState();
}

class _DriverLoadDetailScreenState extends State<DriverLoadDetailScreen> {
  final _firestoreService = FirestoreService();
  final _milesController = TextEditingController();
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _milesController.dispose();
    super.dispose();
  }

  /// Start the trip
  Future<void> _startTrip() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.startTrip(widget.load.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUpdating = false;
      });
    }
  }

  /// Complete the trip
  Future<void> _completeTrip() async {
    final miles = double.tryParse(_milesController.text);
    if (miles == null || miles <= 0) {
      setState(() => _errorMessage = 'Please enter valid miles');
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.endTrip(widget.load.id, miles);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUpdating = false;
      });
    }
  }

  /// Navigate to POD upload screen
  void _uploadPOD() {
    Navigator.pushNamed(
      context,
      '/driver/upload-pod',
      arguments: widget.load.id,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'picked_up':
        return 'Picked Up';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.load.loadNumber),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _getStatusColor(widget.load.status),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusLabel(widget.load.status),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.load.status),
                          ),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow('Load Number', widget.load.loadNumber),
                    _buildDetailRow('Rate', '\$${widget.load.rate.toStringAsFixed(2)}'),
                    _buildDetailRow('Miles', widget.load.miles > 0 
                        ? '${widget.load.miles.toStringAsFixed(1)} mi' 
                        : 'Not recorded'),
                    const SizedBox(height: 8),
                    const Text(
                      'Pickup Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.load.pickupAddress),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delivery Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.load.deliveryAddress),
                        ),
                      ],
                    ),
                    if (widget.load.tripStartAt != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Trip Started',
                        DateFormat('MMM dd, yyyy hh:mm a').format(widget.load.tripStartAt!),
                      ),
                    ],
                    if (widget.load.deliveredAt != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Delivered',
                        DateFormat('MMM dd, yyyy hh:mm a').format(widget.load.deliveredAt!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PODs Section
            if (widget.load.status == 'delivered' || widget.load.status == 'in_transit') ...[
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
                            'Proof of Delivery',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.load.status != 'delivered')
                            TextButton.icon(
                              onPressed: _uploadPOD,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Add POD'),
                            ),
                        ],
                      ),
                      const Divider(),
                      StreamBuilder<List<POD>>(
                        stream: _firestoreService.streamPods(widget.load.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final pods = snapshot.data ?? [];
                          if (pods.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No PODs uploaded yet'),
                              ),
                            );
                          }

                          return Column(
                            children: pods.map((pod) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      pod.imageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.error),
                                          ),
                                        );
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Uploaded: ${DateFormat('MMM dd, yyyy hh:mm a').format(pod.uploadedAt)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (pod.notes.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text('Notes: ${pod.notes}'),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            if (widget.load.status == 'assigned') ...[
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _isUpdating
                  ? const Center(child: CircularProgressIndicator())
                  : AppButton(
                      label: 'Start Trip',
                      onPressed: _startTrip,
                    ),
            ],

            if (widget.load.status == 'in_transit') ...[
              TextField(
                controller: _milesController,
                decoration: const InputDecoration(
                  labelText: 'Total Miles',
                  border: OutlineInputBorder(),
                  suffixText: 'mi',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _isUpdating
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        AppButton(
                          label: 'Upload POD',
                          onPressed: _uploadPOD,
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Complete Trip',
                          onPressed: _completeTrip,
                        ),
                      ],
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
