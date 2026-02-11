import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/navigation_service.dart';
import '../../services/truck_service.dart';
import '../../models/driver.dart';
import '../../models/truck.dart';

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
  final _truckService = TruckService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showAddDriverDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedTruckId;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                StreamBuilder<List<Truck>>(
                  stream: _truckService.streamAvailableTrucks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final trucks = snapshot.data ?? [];
                    
                    if (trucks.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No available trucks. Add trucks first.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedTruckId,
                      decoration: const InputDecoration(
                        labelText: 'Select Truck',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      hint: const Text('Choose a truck'),
                      items: trucks.map((truck) {
                        return DropdownMenuItem<String>(
                          value: truck.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                truck.truckNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                truck.displayInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedTruckId = value);
                      },
                    );
                  },
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
                    selectedTruckId == null) {
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
                  'truckId': selectedTruckId!,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        print('🚀 Starting driver registration process...');
        
        // Get the selected truck
        final truck = await _truckService.getTruck(result['truckId']!);
        if (truck == null) {
          if (mounted) {
            NavigationService.showError('Selected truck not found');
          }
          return;
        }
        
        // Register the driver with Firebase Auth and create user profile
        final credential = await _authService.register(
          email: result['email']!,
          password: result['password']!,
          name: result['name']!,
          role: 'driver',
          phone: result['phone']!,
          truckNumber: truck.truckNumber,
        );

        print('✅ Firebase Auth user created: ${credential?.user?.uid}');

        // Create driver document
        if (credential?.user?.uid != null) {
          print('📝 Creating driver document in Firestore...');
          await _firestoreService.createDriver(
            driverId: credential!.user!.uid,
            name: result['name']!,
            phone: result['phone']!,
            email: result['email']!,
            truckNumber: truck.truckNumber,
          );
          print('✅ Driver document created successfully');
          
          // Assign truck to driver
          await _truckService.assignDriver(
            truckId: result['truckId']!,
            driverId: credential.user!.uid,
            driverName: result['name']!,
          );
          print('✅ Truck assigned to driver');
        } else {
          print('❌ No user ID returned from registration');
        }

        if (mounted) {
          NavigationService.showSuccess('Driver added successfully. Verification email sent.');
        }
      } on FirebaseAuthException catch (e) {
        print('❌ FirebaseAuthException: ${e.code}');
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
        print('❌ Unexpected error: $e');
        if (mounted) {
          NavigationService.showError('Error adding driver: $e');
        }
      }
    }
  }

  Future<void> _showEditDriverDialog(Driver driver) async {
    final nameController = TextEditingController(text: driver.name);
    final phoneController = TextEditingController(text: driver.phone);
    
    // Find the truck currently assigned to this driver
    Truck? currentTruck;
    try {
      currentTruck = await _truckService.getTruckByDriverId(driver.id);
    } catch (e) {
      print('Error fetching current truck: $e');
    }
    
    String? selectedTruckId = currentTruck?.id;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
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
                StreamBuilder<List<Truck>>(
                  stream: _truckService.streamAvailableTrucks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    var trucks = snapshot.data ?? [];
                    
                    // Add currently assigned truck to the list if it's not in available trucks
                    if (currentTruck != null && 
                        !trucks.any((t) => t.id == currentTruck!.id)) {
                      trucks = [currentTruck, ...trucks];
                    }
                    
                    if (trucks.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No available trucks.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedTruckId,
                      decoration: const InputDecoration(
                        labelText: 'Select Truck',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      hint: const Text('Choose a truck'),
                      items: trucks.map((truck) {
                        return DropdownMenuItem<String>(
                          value: truck.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                truck.truckNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                truck.displayInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedTruckId = value);
                      },
                    );
                  },
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
                    selectedTruckId == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'truckId': selectedTruckId!,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      try {
        // Get the selected truck
        final truck = await _truckService.getTruck(result['truckId']!);
        if (truck == null) {
          if (mounted) {
            NavigationService.showError('Selected truck not found');
          }
          return;
        }
        
        await _firestoreService.updateDriver(
          driverId: driver.id,
          name: result['name']!,
          phone: result['phone']!,
          truckNumber: truck.truckNumber,
        );
        
        // Update truck assignment if changed
        if (currentTruck?.id != result['truckId']) {
          // Unassign from old truck if any
          if (currentTruck != null) {
            await _truckService.unassignDriver(currentTruck.id);
          }
          
          // Assign to new truck
          await _truckService.assignDriver(
            truckId: result['truckId']!,
            driverId: driver.id,
            driverName: result['name']!,
          );
        }

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
        content: Text('Are you sure you want to delete ${driver.name}? This will deactivate the driver account and unassign their truck.'),
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
        // Unassign truck if driver has one
        try {
          final truck = await _truckService.getTruckByDriverId(driver.id);
          if (truck != null) {
            await _truckService.unassignDriver(truck.id);
          }
        } catch (e) {
          print('Error unassigning truck: $e');
        }
        
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
          // Enhanced error handling
          if (snapshot.hasError) {
            print('❌ Error in StreamBuilder: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading drivers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
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
            print('⏳ Waiting for driver data...');
            return const Center(child: CircularProgressIndicator());
          }

          final drivers = snapshot.data ?? [];
          print('📋 Total drivers received: ${drivers.length}');
          
          // Filter out inactive drivers
          final activeDrivers = drivers.where((d) => d.isActive).toList();
          print('✅ Active drivers: ${activeDrivers.length}');

          if (activeDrivers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Active Drivers Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a driver to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (drivers.isNotEmpty && activeDrivers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '${drivers.length} inactive driver(s) hidden',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
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
