import 'package:flutter/material.dart';
import '../../models/load_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';

class AdminLoadDetail extends StatefulWidget {
  final LoadModel load;

  const AdminLoadDetail({super.key, required this.load});

  @override
  State<AdminLoadDetail> createState() => _AdminLoadDetailState();
}

class _AdminLoadDetailState extends State<AdminLoadDetail> {
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Load #${widget.load.loadNumber}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${widget.load.status}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Driver ID: ${widget.load.driverId}'),
            const SizedBox(height: 8),
            Text('Pickup: ${widget.load.pickupAddress}'),
            const SizedBox(height: 8),
            Text('Delivery: ${widget.load.deliveryAddress}'),
            const SizedBox(height: 8),
            Text('Rate: \$${widget.load.rate.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            if (widget.load.tripStartTime != null)
              Text('Trip Started: ${widget.load.tripStartTime}'),
            if (widget.load.tripEndTime != null)
              Text('Trip Ended: ${widget.load.tripEndTime}'),
            if (widget.load.miles != null)
              Text('Miles: ${widget.load.miles}'),
            const SizedBox(height: 24),
            const Text('Update Status:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  text: 'Assigned',
                  onPressed: () => _updateStatus('assigned'),
                  loading: _loading,
                ),
                AppButton(
                  text: 'Picked Up',
                  onPressed: () => _updateStatus('picked_up'),
                  loading: _loading,
                ),
                AppButton(
                  text: 'In Transit',
                  onPressed: () => _updateStatus('in_transit'),
                  loading: _loading,
                ),
                AppButton(
                  text: 'Delivered',
                  onPressed: () => _updateStatus('delivered'),
                  loading: _loading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
