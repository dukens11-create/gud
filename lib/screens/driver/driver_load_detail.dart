import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import 'upload_pod_screen.dart';

class DriverLoadDetail extends StatefulWidget {
  final LoadModel load;

  const DriverLoadDetail({
    super.key,
    required this.load,
  });

  @override
  State<DriverLoadDetail> createState() => _DriverLoadDetailState();
}

class _DriverLoadDetailState extends State<DriverLoadDetail> {
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateLoadStatus(widget.load.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startTrip() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.startTrip(widget.load.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _endTrip() async {
    final milesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: TextField(
          controller: milesController,
          decoration: const InputDecoration(
            labelText: 'Miles Driven',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.endTrip(widget.load.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip ended and marked as delivered')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
    milesController.dispose();
  }

  void _uploadPOD() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPodScreen(loadId: widget.load.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load #${widget.load.loadNumber}'),
      ),
      body: StreamBuilder<LoadModel>(
        stream: _firestoreService.streamDriverLoads(widget.load.driverId).map(
          (loads) => loads.firstWhere(
            (l) => l.id == widget.load.id,
            orElse: () => widget.load,
          ),
        ),
        initialData: widget.load,
        builder: (context, snapshot) {
          final load = snapshot.data ?? widget.load;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(
                  title: 'Load Information',
                  children: [
                    _InfoRow(label: 'Load Number', value: load.loadNumber),
                    _InfoRow(label: 'Status', value: load.status.toUpperCase()),
                    _InfoRow(label: 'Rate', value: '\$${load.rate.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Addresses',
                  children: [
                    _InfoRow(label: 'Pickup', value: load.pickupAddress),
                    _InfoRow(label: 'Delivery', value: load.deliveryAddress),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Trip Times',
                  children: [
                    _InfoRow(
                      label: 'Start Time',
                      value: load.tripStartTime != null
                          ? DateFormat('MMM dd, yyyy HH:mm').format(load.tripStartTime!)
                          : 'Not started',
                    ),
                    _InfoRow(
                      label: 'End Time',
                      value: load.tripEndTime != null
                          ? DateFormat('MMM dd, yyyy HH:mm').format(load.tripEndTime!)
                          : 'Not ended',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (load.status == 'assigned') ...[
                  AppButton(
                    text: 'Mark as Picked Up',
                    onPressed: () => _updateStatus('picked_up'),
                    isLoading: _isLoading,
                  ),
                ],
                if (load.status == 'picked_up') ...[
                  AppButton(
                    text: 'Start Trip',
                    onPressed: _startTrip,
                    isLoading: _isLoading,
                  ),
                ],
                if (load.status == 'in_transit') ...[
                  AppButton(
                    text: 'End Trip',
                    onPressed: _endTrip,
                    isLoading: _isLoading,
                  ),
                ],
                if (load.status == 'delivered' || load.status == 'in_transit') ...[
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Upload POD',
                    onPressed: _uploadPOD,
                    color: Colors.green,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
