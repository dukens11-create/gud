import 'package:flutter/material.dart';
import '../../models/load_model.dart';
import '../../models/driver.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
  bool _loading = false;

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

    setState(() => _loading = true);
    try {
      final load = LoadModel(
        id: '',
        loadNumber: _loadNumberController.text.trim(),
        driverId: _selectedDriverId!,
        pickupAddress: _pickupController.text.trim(),
        deliveryAddress: _deliveryController.text.trim(),
        rate: double.parse(_rateController.text.trim()),
        status: 'assigned',
      );
      await _firestoreService.createLoad(load);
      _loadNumberController.clear();
      _pickupController.clear();
      _deliveryController.clear();
      _rateController.clear();
      setState(() => _selectedDriverId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load created successfully')),
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
  void dispose() {
    _loadNumberController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Load')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppTextField(
              label: 'Load Number',
              controller: _loadNumberController,
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Driver>>(
              stream: _firestoreService.streamDrivers(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }

                final drivers = snap.data!;
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
            AppTextField(
              label: 'Pickup Address',
              controller: _pickupController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Delivery Address',
              controller: _deliveryController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Rate',
              controller: _rateController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Create Load',
                onPressed: _createLoad,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
