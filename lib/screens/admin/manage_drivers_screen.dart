import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_service.dart';
import '../../models/driver.dart';

/// Manage Drivers Screen - Full driver management functionality
/// 
/// This screen allows admins to add, edit, and delete drivers.
class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showAddDriverDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final truckController = TextEditingController();

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: truckController,
                decoration: const InputDecoration(
                  labelText: 'Truck Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Validate before closing dialog (trim to prevent whitespace-only entries)
              if (nameController.text.trim().isEmpty || 
                  emailController.text.trim().isEmpty ||
                  passwordController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty || 
                  truckController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'password': passwordController.text.trim(),
                'phone': phoneController.text.trim(),
                'truckNumber': truckController.text.trim(),
              });
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        // Register the driver with Firebase Auth and create user profile
        final credential = await _authService.register(
          email: result['email']!,
          password: result['password']!,
          name: result['name']!,
          role: 'driver',
          phone: result['phone']!,
          truckNumber: result['truckNumber']!,
        );

        // Create driver document
        if (credential?.user?.uid != null) {
          await _firestoreService.createDriver(
            driverId: credential!.user!.uid,
            name: result['name']!,
            phone: result['phone']!,
            truckNumber: result['truckNumber']!,
          );
        }

        if (mounted) {
          NavigationService.showSuccess('Driver added successfully. Verification email sent.');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage = 'Failed to add driver';
          if (e.code == 'email-already-in-use') {
            errorMessage = 'This email is already registered';
          } else if (e.code == 'invalid-email') {
            errorMessage = 'Invalid email address';
          } else if (e.code == 'weak-password') {
            errorMessage = 'Password is too weak';
          }
          NavigationService.showError(errorMessage);
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error adding driver: $e');
        }
      }
    }
  }

  Future<void> _showEditDriverDialog(Driver driver) async {
    final nameController = TextEditingController(text: driver.name);
    final phoneController = TextEditingController(text: driver.phone);
    final truckController = TextEditingController(text: driver.truckNumber);

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Driver'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: truckController,
                decoration: const InputDecoration(
                  labelText: 'Truck Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Validate before closing dialog (trim to prevent whitespace-only entries)
              if (nameController.text.trim().isEmpty || 
                  phoneController.text.trim().isEmpty || 
                  truckController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              Navigator.pop(dialogContext, {
                'name': nameController.text.trim(),
                'phone': phoneController.text.trim(),
                'truckNumber': truckController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await _firestoreService.updateDriver(
          driverId: driver.id,
          name: result['name']!,
          phone: result['phone']!,
          truckNumber: result['truckNumber']!,
        );

        if (mounted) {
          NavigationService.showSuccess('Driver updated successfully');
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error updating driver: $e');
        }
      }
    }
  }

  Future<void> _showDeleteDriverDialog(Driver driver) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.name}? This will deactivate the driver account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Deactivate driver instead of deleting
        await _firestoreService.updateDriver(
          driverId: driver.id,
          isActive: false,
        );

        if (mounted) {
          NavigationService.showSuccess('Driver deactivated successfully');
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error deactivating driver: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
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
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Force rebuild
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data ?? [];
          
          // Filter out inactive drivers
          final activeDrivers = drivers.where((d) => d.isActive).toList();

          if (activeDrivers.isEmpty) {
            return const Center(
              child: Text('No drivers found. Add one to get started!'),
            );
          }

          return ListView.builder(
            itemCount: activeDrivers.length,
            itemBuilder: (context, index) {
              final driver = activeDrivers[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(driver.name.isNotEmpty ? driver.name[0] : '?'),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
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
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDriverDialog(driver);
                          } else if (value == 'deactivate') {
                            _showDeleteDriverDialog(driver);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'deactivate',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Deactivate', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
