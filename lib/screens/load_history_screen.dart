import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/load.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';

class LoadHistoryScreen extends StatefulWidget {
  const LoadHistoryScreen({super.key});

  @override
  State<LoadHistoryScreen> createState() => _LoadHistoryScreenState();
}

class _LoadHistoryScreenState extends State<LoadHistoryScreen> {
  final _searchController = TextEditingController();
  final _exportService = ExportService();
  
  String? _selectedStatus;
  String _sortBy = 'date';
  DateTime? _startDate;
  DateTime? _endDate;
  
  List<LoadModel> _loads = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _limit = 20;
  DocumentSnapshot? _lastDocument;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool loadMore = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _loads = [];
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      Query query = FirebaseFirestore.instance.collection('loads');

      // Apply filters
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      if (_startDate != null && _endDate != null) {
        query = query
            .where('createdAt', isGreaterThanOrEqualTo: _startDate!.toIso8601String())
            .where('createdAt', isLessThanOrEqualTo: _endDate!.toIso8601String());
      }

      // Apply sorting
      if (_sortBy == 'date') {
        query = query.orderBy('createdAt', descending: true);
      } else if (_sortBy == 'amount') {
        query = query.orderBy('rate', descending: true);
      }

      // Pagination
      if (loadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(_limit);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      final newLoads = snapshot.docs
          .map((doc) => LoadModel.fromDoc(doc))
          .toList();

      // Apply search filter (client-side)
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        newLoads.removeWhere((load) =>
            !load.loadNumber.toLowerCase().contains(searchQuery));
      }

      setState(() {
        if (loadMore) {
          _loads.addAll(newLoads);
        } else {
          _loads = newLoads;
        }
        _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
      _loadData();
    }
  }

  Future<void> _exportToCSV() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date range first'),
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final filePath = await _exportService.exportLoadsToCSV(_startDate!, _endDate!);

      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export saved: $filePath')),
        );

        // Share the file
        await Share.shareXFiles([XFile(filePath)], text: 'Load Report');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCSV,
            tooltip: 'Export to CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters section
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by load number',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (_) => _loadData(),
                ),
                const SizedBox(height: 8),

                // Filter chips
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Date range chip
                            ActionChip(
                              avatar: const Icon(Icons.date_range, size: 18),
                              label: Text(
                                _startDate != null && _endDate != null
                                    ? '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}'
                                    : 'Date Range',
                              ),
                              onPressed: _selectDateRange,
                            ),
                            const SizedBox(width: 8),

                            // Status dropdown
                            DropdownButton<String?>(
                              value: _selectedStatus,
                              hint: const Text('Status'),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Statuses'),
                                ),
                                const DropdownMenuItem(
                                  value: 'assigned',
                                  child: Text('Assigned'),
                                ),
                                const DropdownMenuItem(
                                  value: 'picked_up',
                                  child: Text('Picked Up'),
                                ),
                                const DropdownMenuItem(
                                  value: 'in_transit',
                                  child: Text('In Transit'),
                                ),
                                const DropdownMenuItem(
                                  value: 'delivered',
                                  child: Text('Delivered'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                                _loadData();
                              },
                            ),
                            const SizedBox(width: 8),

                            // Sort dropdown
                            DropdownButton<String>(
                              value: _sortBy,
                              hint: const Text('Sort By'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'date',
                                  child: Text('Date'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount',
                                  child: Text('Amount'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                  });
                                  _loadData();
                                }
                              },
                            ),

                            // Clear filters
                            if (_selectedStatus != null ||
                                _startDate != null ||
                                _searchController.text.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = null;
                                    _startDate = null;
                                    _endDate = null;
                                    _searchController.clear();
                                  });
                                  _loadData();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results count
          if (_loads.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${_loads.length} load${_loads.length == 1 ? '' : 's'} found',
                style: const TextStyle(color: Colors.grey),
              ),
            ),

          // Loads list
          Expanded(
            child: _isLoading && _loads.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _loads.isEmpty
                    ? const Center(child: Text('No loads found'))
                    : ListView.builder(
                        itemCount: _loads.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _loads.length) {
                            // Load more button
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _loadData(loadMore: true),
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text('Load More'),
                                ),
                              ),
                            );
                          }

                          final load = _loads[index];
                          return _buildLoadCard(load);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadCard(LoadModel load) {
    final statusColor = _getStatusColor(load.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.local_shipping, color: statusColor),
        ),
        title: Text(
          load.loadNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (load.driverName != null)
              Text('Driver: ${load.driverName}'),
            Text('Pickup: ${load.pickupAddress}'),
            Text('Delivery: ${load.deliveryAddress}'),
            Text('Created: ${_dateFormat.format(load.createdAt)}'),
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
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatStatus(load.status),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
