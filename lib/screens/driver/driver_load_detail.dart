import 'package:flutter/material.dart';
import '../../models/load_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import 'upload_pod_screen.dart';

class DriverLoadDetail extends StatefulWidget {
  final LoadModel load;

  const DriverLoadDetail({super.key, required this.load});

  @override
  State<DriverLoadDetail> createState() => _DriverLoadDetailState();
}

class _DriverLoadDetailState extends State<DriverLoadDetail> {
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _markPickedUp() async {
    setState(() => _loading = true);
    try {
      await _firestoreService.updateLoadStatus(widget.load.id, 'picked_up');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as picked up')),
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

  Future<void> _startTrip() async {
    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _endTrip() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Miles'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _loading = true);
      try {
        final miles = double.parse(result);
        await _firestoreService.endTrip(widget.load.id, miles);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip ended')),
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
            if (widget.load.status == 'assigned')
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Mark Picked Up',
                  onPressed: _markPickedUp,
                  loading: _loading,
                ),
              ),
            if (widget.load.status == 'picked_up')
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Start Trip',
                  onPressed: _startTrip,
                  loading: _loading,
                ),
              ),
            if (widget.load.status == 'in_transit')
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'End Trip',
                  onPressed: _endTrip,
                  loading: _loading,
                ),
              ),
            const SizedBox(height: 16),
            if (widget.load.status == 'delivered' || widget.load.status == 'in_transit')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UploadPodScreen(loadId: widget.load.id),
                      ),
                    );
                  },
                  child: const Text('Upload POD'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
