import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../models/load.dart';
import 'package:intl/intl.dart';

/// Load History Screen - View past loads and deliveries
class LoadHistoryScreen extends StatefulWidget {
  const LoadHistoryScreen({super.key});

  @override
  State<LoadHistoryScreen> createState() => _LoadHistoryScreenState();
}

class _LoadHistoryScreenState extends State<LoadHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'load_history');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<LoadModel>> _getFilteredLoads() {
    return _firestoreService.streamAllLoads().map((loads) {
      // Filter to show only completed/delivered loads
      var filteredLoads = loads.where((load) {
        final isCompleted = load.status == 'delivered' || load.status == 'completed';
        
        if (_statusFilter != 'all' && !isCompleted) {
          return false;
        }

        final matchesSearch = _searchQuery.isEmpty ||
            load.loadNumber.toLowerCase().contains(_searchQuery) ||
            load.pickupAddress.toLowerCase().contains(_searchQuery) ||
            load.deliveryAddress.toLowerCase().contains(_searchQuery);

        return matchesSearch;
      }).toList();

      // Sort by date (newest first)
      filteredLoads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredLoads;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load History'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search by load number or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Load List
          Expanded(
            child: StreamBuilder<List<LoadModel>>(
              stream: _getFilteredLoads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final loads = snapshot.data ?? [];

                if (loads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No loads found matching your search'
                              : 'No load history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: loads.length,
                  itemBuilder: (context, index) {
                    final load = loads[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(load.status),
                          child: Text(
                            load.status.isNotEmpty ? load.status[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          load.loadNumber.isNotEmpty ? load.loadNumber : 'Unknown Load',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('From: ${load.pickupAddress.isNotEmpty ? load.pickupAddress : "Unknown"}'),
                            Text('To: ${load.deliveryAddress.isNotEmpty ? load.deliveryAddress : "Unknown"}'),
                            const SizedBox(height: 4),
                            Text(
                              'Completed: ${DateFormat('MMM dd, yyyy').format(load.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${load.rate.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(load.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                load.status.isNotEmpty ? load.status : 'unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Could navigate to load detail screen
                          AnalyticsService.instance.logSelectContent(
                            contentType: 'load_history',
                            itemId: load.loadNumber,
                          );
                        },
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'in_transit':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
