import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../models/driver.dart';

class ManageDriversScreen extends StatelessWidget {
  const ManageDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
      ),
      body: FutureBuilder<List<Driver>>(
        future: mockService.getDrivers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data ?? [];

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(driver.name[0]),
                  ),
                  title: Text(driver.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phone: ${driver.phone}'),
                      Text('Truck: ${driver.truckNumber}'),
                      Text('Status: ${driver.status}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${driver.totalEarnings.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('${driver.completedLoads} loads'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Driver management is disabled in demo mode'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

    try {
      // Create Firebase Auth user
      final userCredential = await _authService.createUser(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Create user doc with role
      await _authService.ensureUserDoc(
        uid: userCredential.user!.uid,
        role: 'driver',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        truckNumber: _truckNumberController.text.trim(),
      );

      // Create driver doc
      await _firestoreService.createDriver(
        driverId: userCredential.user!.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        truckNumber: _truckNumberController.text.trim(),
      );

      // Clear form
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();
      _truckNumberController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver created successfully')),
        );
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
      appBar: AppBar(title: const Text('Manage Drivers')),
      body: Column(
        children: [
          // Form section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Driver',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameController,
                      label: 'Name',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _truckNumberController,
                      label: 'Truck Number',
                    ),
                    const SizedBox(height: 16),
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
                            label: 'Create Driver',
                            onPressed: _createDriver,
                          ),
                  ],
                ),
              ),
            ),
          ),
          // Drivers list
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Existing Drivers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Driver>>(
              stream: _firestoreService.streamDrivers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final drivers = snapshot.data ?? [];

                if (drivers.isEmpty) {
                  return const Center(child: Text('No drivers yet'));
                }

                return ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D'),
                        ),
                        title: Text(driver.name),
                        subtitle: Text(
                          'Phone: ${driver.phone}\nTruck: ${driver.truckNumber}',
                        ),
                        trailing: Chip(
                          label: Text(driver.status),
                        ),
                      ),
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
