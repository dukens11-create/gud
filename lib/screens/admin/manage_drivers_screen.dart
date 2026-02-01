import 'package:flutter/material.dart';
import '../../models/driver.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _truckController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _addDriver() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _truckController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final driver = Driver(
        id: '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        truckNumber: _truckController.text.trim(),
      );
      await _firestoreService.createDriver(driver);
      _nameController.clear();
      _phoneController.clear();
      _truckController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver added successfully')),
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
    _nameController.dispose();
    _phoneController.dispose();
    _truckController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Drivers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AppTextField(
                  label: 'Driver Name',
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Truck Number',
                  controller: _truckController,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Add Driver',
                    onPressed: _addDriver,
                    loading: _loading,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('All Drivers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<Driver>>(
              stream: _firestoreService.streamDrivers(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final drivers = snap.data!;
                if (drivers.isEmpty) {
                  return const Center(child: Text('No drivers'));
                }

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      title: Text(driver.name),
                      subtitle: Text('${driver.phone} - Truck: ${driver.truckNumber}'),
                      trailing: Text(driver.status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
