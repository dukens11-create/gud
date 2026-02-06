import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/load.dart';
import '../services/export_service.dart';
import '../services/pdf_generator_service.dart';

class LoadHistoryScreen extends StatefulWidget {
  const LoadHistoryScreen({Key? key}) : super(key: key);

  @override
  State<LoadHistoryScreen> createState() => _LoadHistoryScreenState();
}

class _LoadHistoryScreenState extends State<LoadHistoryScreen> {
  final _exportService = ExportService();
  final _pdfService = PdfGeneratorService();
  final _searchController = TextEditingController();
  
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  bool _isExporting = false;
  
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Stream<List<LoadModel>> _getLoadsStream() {
    Query query = FirebaseFirestore.instance.collection('loads');
    
    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: _startDate!.toIso8601String());
    }
    
    if (_endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: _endDate!.toIso8601String());
    }
    
    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList());
  }
  
  List<LoadModel> _filterLoads(List<LoadModel> loads) {
    if (_searchQuery.isEmpty) return loads;
    
    final query = _searchQuery.toLowerCase();
    return loads.where((load) {
      return load.loadNumber.toLowerCase().contains(query) ||
             (load.driverName?.toLowerCase().contains(query) ?? false) ||
             load.pickupAddress.toLowerCase().contains(query) ||
             load.deliveryAddress.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
  
  Future<void> _exportToCSV(List<LoadModel> loads) async {
    setState(() => _isExporting = true);
    
    try {
      final file = await _exportService.exportLoadsToCSV(
        loads: loads,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      await _exportService.shareFile(file);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
  
  Future<void> _exportToPDF(List<LoadModel> loads) async {
    setState(() => _isExporting = true);
    
    try {
      final file = await _pdfService.generateLoadReportPDF(
        loads: loads,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      await _exportService.shareFile(file);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generation failed: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
  
  void _showExportOptions(List<LoadModel> loads) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export to CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV(loads);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export to PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF(loads);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Load History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by load #, driver, or location...',
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
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'assigned', label: Text('Pending')),
                          ButtonSegment(value: 'in_transit', label: Text('In Progress')),
                          ButtonSegment(value: 'delivered', label: Text('Delivered')),
                        ],
                        selected: {_selectedStatus},
                        onSelectionChanged: (Set<String> selected) {
                          setState(() => _selectedStatus = selected.first);
                        },
                      ),
                    ),
                  ],
                ),
                if (_startDate != null && _endDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(
                        '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LoadModel>>(
              stream: _getLoadsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final loads = _filterLoads(snapshot.data!);
                
                if (loads.isEmpty) {
                  return const Center(
                    child: Text('No loads found'),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: loads.length,
                    itemBuilder: (context, index) {
                      final load = loads[index];
                      return _buildLoadCard(load);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<List<LoadModel>>(
        stream: _getLoadsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          
          final loads = _filterLoads(snapshot.data!);
          
          return FloatingActionButton.extended(
            onPressed: _isExporting ? null : () => _showExportOptions(loads),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download),
            label: const Text('Export'),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadCard(LoadModel load) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Navigate to load details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    load.loadNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(load.status),
                ],
              ),
              const SizedBox(height: 8),
              if (load.driverName != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(load.driverName!),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${load.pickupAddress} → ${load.deliveryAddress}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currencyFormat.format(load.rate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${load.miles.toStringAsFixed(0)} mi',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _dateFormat.format(load.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'in_transit':
        color = Colors.blue;
        label = 'In Progress';
        break;
      case 'picked_up':
        color = Colors.orange;
        label = 'Picked Up';
        break;
      default:
        color = Colors.grey;
        label = 'Pending';
    }
    
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
