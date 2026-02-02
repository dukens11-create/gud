import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/driver.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_textfield.dart';

class CreateLoadScreen extends StatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _firestoreService = FirestoreService();
  final _loadNumberController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _rateController = TextEditingController();
  String? _selectedDriverId;
  bool _isCreating = false;
  String? _errorMessage;

  @override
  void dispose() {
    _loadNumberController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _createLoad() async {
    if (_loadNumberController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _deliveryController.text.isEmpty ||
        _rateController.text.isEmpty ||
        _selectedDriverId == null) {
      setState(() => _errorMessage = 'All fields are required');
      return;
    }

    final rate = double.tryParse(_rateController.text);
    if (rate == null) {
      setState(() => _errorMessage = 'Invalid rate amount');
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.createLoad(
        loadNumber: _loadNumberController.text.trim(),
        driverId: _selectedDriverId!,
        pickupAddress: _pickupController.text.trim(),
        deliveryAddress: _deliveryController.text.trim(),
        rate: rate,
      );

      // Clear form
      _loadNumberController.clear();
      _pickupController.clear();
      _deliveryController.clear();
      _rateController.clear();
      _selectedDriverId = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Load')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _loadNumberController,
              label: 'Load Number',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _pickupController,
              label: 'Pickup Address',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _deliveryController,
              label: 'Delivery Address',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _rateController,
              label: 'Rate (\$)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Driver',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Driver>>(
              stream: _firestoreService.streamDrivers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final drivers = snapshot.data ?? [];

                if (drivers.isEmpty) {
                  return const Text('No drivers available. Create a driver first.');
                }

                final availableDrivers = drivers.where((d) => d.status == 'available').toList();

                if (availableDrivers.isEmpty) {
                  return const Text('No available drivers at the moment.');
                }

                return DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a driver',
                  ),
                  items: availableDrivers.map((driver) {
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
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            _isCreating
                ? const Center(child: CircularProgressIndicator())
                : AppButton(
                    label: 'Create Load',
                    onPressed: _createLoad,
                  ),
          ],
        ),
      ),
    );
  }
}
