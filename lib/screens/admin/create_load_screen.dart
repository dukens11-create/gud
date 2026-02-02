import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/driver.dart';

class CreateLoadScreen extends StatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _loadNumberController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _rateController = TextEditingController();
  final _firestoreService = FirestoreService();
  String? _selectedDriverId;
  bool _isLoading = false;

  Future<void> _createLoad() async {
    if (_loadNumberController.text.isEmpty ||
        _selectedDriverId == null ||
        _pickupController.text.isEmpty ||
        _deliveryController.text.isEmpty ||
        _rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')), 
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestoreService.createLoad(
        loadNumber: _loadNumberController.text.trim(),
        driverId: _selectedDriverId!,
        pickupAddress: _pickupController.text.trim(),
        deliveryAddress: _deliveryController.text.trim(),
        rate: double.parse(_rateController.text.trim()),
      );

      _loadNumberController.clear();
      _pickupController.clear();
      _deliveryController.clear();
      _rateController.clear();
      setState(() => _selectedDriverId = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load created successfully')), 
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')), 
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Load')), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loadNumberController,
              decoration: const InputDecoration(
                labelText: 'Load Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Driver>>(
              stream: _firestoreService.streamDrivers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final drivers = snapshot.data!
                    .where((d) => d.status == 'available')
                    .toList();

                if (drivers.isEmpty) {
                  return const Text('No available drivers');
                }

                return DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Driver',
                    border: OutlineInputBorder(),
                  ),
                  items: drivers.map((driver) {
                    return DropdownMenuItem(
                      value: driver.id,
                      child: Text('${driver.name} - ${driver.truckNumber}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedDriverId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                labelText: 'Pickup Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deliveryController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Rate (4)',
                border: OutlineInputBorder(),
                prefixText: '4 ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createLoad,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Create Load', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadNumberController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _rateController.dispose();
    super.dispose();
  }
}