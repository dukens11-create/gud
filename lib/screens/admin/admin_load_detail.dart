import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';

class AdminLoadDetail extends StatefulWidget {
  final LoadModel load;

  const AdminLoadDetail({
    super.key,
    required this.load,
  });

  @override
  State<AdminLoadDetail> createState() => _AdminLoadDetailState();
}

class _AdminLoadDetailState extends State<AdminLoadDetail> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load #${widget.load.loadNumber}'),
      ),
      body: StreamBuilder<List<LoadModel>>(
        stream: _firestoreService.streamAllLoads(),
        builder: (context, snapshot) {
          LoadModel load = widget.load;
          if (snapshot.hasData) {
            try {
              load = snapshot.data!.firstWhere((l) => l.id == widget.load.id);
            } catch (e) {
              load = widget.load;
            }
          }

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
                    _InfoRow(label: 'Driver', value: load.driverName),
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
                      label: 'Created',
                      value: DateFormat('MMM dd, yyyy HH:mm').format(load.createdAt),
                    ),
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
                const Text(
                  'Admin Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Set to Assigned',
                  onPressed: () => _updateStatus('assigned'),
                  isLoading: _isLoading,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: 'Set to Picked Up',
                  onPressed: () => _updateStatus('picked_up'),
                  isLoading: _isLoading,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: 'Set to In Transit',
                  onPressed: () => _updateStatus('in_transit'),
                  isLoading: _isLoading,
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
                AppButton(
                  text: 'Set to Delivered',
                  onPressed: () => _updateStatus('delivered'),
                  isLoading: _isLoading,
                  color: Colors.green,
                ),
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
