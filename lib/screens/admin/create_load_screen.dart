import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_textfield.dart';

class CreateLoadScreen extends StatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loadNumberController = TextEditingController();
  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  final _rateController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  Driver? _selectedDriver;
  bool _isLoading = false;

  @override
  void dispose() {
    _loadNumberController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _createLoad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestoreService.createLoad(
        loadNumber: _loadNumberController.text.trim(),
        driverId: _selectedDriver!.id,
        driverName: _selectedDriver!.name,
        pickupAddress: _pickupController.text.trim(),
        deliveryAddress: _deliveryController.text.trim(),
        rate: double.parse(_rateController.text.trim()),
      );

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Load'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Load Number',
                controller: _loadNumberController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter load number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Driver Dropdown
              StreamBuilder<List<Driver>>(
                stream: _firestoreService.streamDrivers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final drivers = snapshot.data ?? [];

                  if (drivers.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No drivers available. Please add drivers first.'),
                      ),
                    );
                  }

                  return DropdownButtonFormField<Driver>(
                    decoration: InputDecoration(
                      labelText: 'Assign Driver',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    value: _selectedDriver,
                    items: drivers.map((driver) {
                      return DropdownMenuItem<Driver>(
                        value: driver,
                        child: Text('${driver.name} - ${driver.truckNumber}'),
                      );
                    }).toList(),
                    onChanged: (driver) {
                      setState(() {
                        _selectedDriver = driver;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a driver';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Pickup Address',
                controller: _pickupController,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Delivery Address',
                controller: _deliveryController,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter delivery address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Rate (\$)',
                controller: _rateController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter rate';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Create Load',
                onPressed: _createLoad,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
