import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../models/load.dart';
import 'load_detail_screen.dart';
import '../login_screen.dart';

class DriverHome extends StatefulWidget {
  final String driverId;
  
  const DriverHome({super.key, required this.driverId});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSendingLocation = false;

  Future<void> _sendLocation() async {
    setState(() {
      _isSendingLocation = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services and grant permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Convert position to map
      final locationData = _locationService.positionToMap(position);

      // Update driver location in Firestore
      await _firestoreService.updateDriverLocation(
        driverId: widget.driverId,
        latitude: locationData['lat'],
        longitude: locationData['lng'],
        timestamp: locationData['timestamp'],
        accuracy: locationData['accuracy'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location sent successfully!\nLat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, '/driver/expenses'),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => Navigator.pushNamed(context, '/driver/earnings'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await mockService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Send Location button at the top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isSendingLocation ? null : _sendLocation,
              icon: _isSendingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_isSendingLocation ? 'Sending...' : 'Send Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          // Loads list
          Expanded(
            child: StreamBuilder<List<LoadModel>>(
              stream: mockService.streamDriverLoads(widget.driverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final loads = snapshot.data ?? [];

                if (loads.isEmpty) {
                  return const Center(
                    child: Text('No loads assigned yet.'),
                  );
                }

                return ListView.builder(
                  itemCount: loads.length,
                  itemBuilder: (context, index) {
                    final load = loads[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoadDetailScreen(load: load),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          child: Text(load.status.isNotEmpty ? load.status[0].toUpperCase() : 'L'),
                        ),
                        title: Text(load.loadNumber),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From: ${load.pickupAddress}'),
                            Text('To: ${load.deliveryAddress}'),
                            Text('Rate: \$${load.rate.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(load.status),
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
