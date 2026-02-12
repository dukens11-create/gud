import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/navigation_service.dart';
import '../../models/driver.dart';
import '../../config/constants.dart';

/// Create load screen - Create a new load assignment
class CreateLoadScreen extends StatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loadNumberController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _rateController = TextEditingController();
  final _milesController = TextEditingController();
  final _notesController = TextEditingController();
  
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _selectedDriverId;
  String? _selectedDriverName;
  bool _isSaving = false;

  @override
  void dispose() {
    _loadNumberController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _rateController.dispose();
    _milesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLoad() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDriverId == null) {
      NavigationService.showError('Please select a driver');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final createdBy = currentUser?.uid ?? kOfflineUserId;

      // Additional validation: Check for duplicate load number
      final loadNumber = _loadNumberController.text.trim();
      final isDuplicate = await _firestoreService.loadNumberExists(loadNumber);
      if (isDuplicate) {
        if (mounted) {
          NavigationService.showError(
            'Load number $loadNumber already exists. Please use a different number.'
          );
          setState(() => _isSaving = false);
        }
        return;
      }

      // Additional validation: Verify driver is valid and active
      final isValidDriver = await _firestoreService.isDriverValid(_selectedDriverId!);
      if (!isValidDriver) {
        if (mounted) {
          NavigationService.showError(
            'Selected driver is not available. Please choose another driver.'
          );
          setState(() => _isSaving = false);
        }
        return;
      }

      // Check driver's current workload
      final activeLoadCount = await _firestoreService.getDriverActiveLoadCount(_selectedDriverId!);
      if (activeLoadCount >= 5) {
        if (mounted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Driver Has Multiple Active Loads'),
              content: Text(
                'This driver currently has $activeLoadCount active load(s). '
                'Are you sure you want to assign another load?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Proceed Anyway'),
                ),
              ],
            ),
          );
          
          if (proceed != true) {
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      await _firestoreService.createLoad(
        loadNumber: loadNumber,
        driverId: _selectedDriverId!,
        driverName: _selectedDriverName!,
        pickupAddress: _pickupAddressController.text.trim(),
        deliveryAddress: _deliveryAddressController.text.trim(),
        rate: double.parse(_rateController.text),
        miles: _milesController.text.isNotEmpty 
            ? double.parse(_milesController.text) 
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        createdBy: createdBy,
      );

      if (mounted) {
        NavigationService.showSuccess(
          'Load $loadNumber created and assigned to $_selectedDriverName'
        );
        Navigator.pop(context);
      }
    } on ArgumentError catch (e) {
      // Handle validation errors from createLoad
      if (mounted) {
        NavigationService.showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        NavigationService.showError('Error creating load: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Load'),
      ),
      body: StreamBuilder<List<Driver>>(
        stream: _firestoreService.streamDrivers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading drivers: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data ?? [];
          final activeDrivers = drivers.where((d) => d.isActive).toList();

          if (activeDrivers.isEmpty) {
            return const Center(
              child: Text('No active drivers available. Please add drivers first.'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                TextFormField(
                  controller: _loadNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Load Number',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., LOAD-001',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a load number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // CRITICAL: driver.id MUST be the Firebase Auth UID, not the driver name
                // This value is stored in the load's driverId field and used for:
                // 1. Driver dashboard queries (where driverId == currentUser.uid)
                // 2. Firestore security rules (resource.data.driverId == request.auth.uid)
                // 3. Email notifications (sent to driver with this UID)
                DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(
                    labelText: 'Driver',
                    border: OutlineInputBorder(),
                  ),
                  items: activeDrivers.map((driver) {
                    return DropdownMenuItem(
                      value: driver.id, // ← This MUST be Firebase Auth UID
                      child: Text('${driver.name} - ${driver.truckNumber}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDriverId = value;
                      _selectedDriverName = activeDrivers
                          .firstWhere((d) => d.id == value)
                          .name;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a driver';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pickupAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pickup address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deliveryAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter delivery address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _milesController,
                  decoration: const InputDecoration(
                    labelText: 'Miles (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveLoad,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Load'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
