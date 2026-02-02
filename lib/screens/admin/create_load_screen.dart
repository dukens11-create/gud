import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final _milesController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedDriverId;
  String? _selectedDriverName;
  bool _isCreating = false;
  bool _isLoadingNumber = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateLoadNumber();
  }

  Future<void> _generateLoadNumber() async {
    setState(() => _isLoadingNumber = true);
    try {
      final loadNumber = await _firestoreService.generateLoadNumber();
      _loadNumberController.text = loadNumber;
    } catch (e) {
      setState(() => _errorMessage = 'Error generating load number: $e');
    } finally {
      setState(() => _isLoadingNumber = false);
    }
  }

  @override
  void dispose() {
    _loadNumberController.dispose();
    _pickupController.dispose();
    _deliveryController.dispose();
    _rateController.dispose();
    _milesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createLoad() async {
    if (_loadNumberController.text.isEmpty ||
        _pickupController.text.isEmpty ||
        _deliveryController.text.isEmpty ||
        _rateController.text.isEmpty ||
        _selectedDriverId == null) {
      setState(() => _errorMessage = 'All required fields must be filled');
      return;
    }

    final rate = double.tryParse(_rateController.text);
    if (rate == null) {
      setState(() => _errorMessage = 'Invalid rate amount');
      return;
    }

    final miles = _milesController.text.isNotEmpty 
        ? double.tryParse(_milesController.text) 
        : null;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      await _firestoreService.createLoad(
        loadNumber: _loadNumberController.text.trim(),
        driverId: _selectedDriverId!,
        driverName: _selectedDriverName ?? '',
        pickupAddress: _pickupController.text.trim(),
        deliveryAddress: _deliveryController.text.trim(),
        rate: rate,
        miles: miles,
        notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        createdBy: currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Load created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
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
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _loadNumberController,
                    label: 'Load Number',
                    enabled: !_isLoadingNumber,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoadingNumber 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoadingNumber ? null : _generateLoadNumber,
                  tooltip: 'Generate new load number',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _pickupController,
              label: 'Pickup Address *',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _deliveryController,
              label: 'Delivery Address *',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _rateController,
              label: 'Rate (\$) *',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _milesController,
              label: 'Estimated Miles (optional)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Driver *',
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

                return DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select a driver',
                  ),
                  items: drivers.map((driver) {
                    return DropdownMenuItem(
                      value: driver.id,
                      child: Text('${driver.name} - ${driver.truckNumber} (${driver.status})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedDriver = drivers.firstWhere((d) => d.id == value);
                    setState(() {
                      _selectedDriverId = value;
                      _selectedDriverName = selectedDriver.name;
                    });
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
