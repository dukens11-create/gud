import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/load.dart';
import '../models/invoice.dart';
import '../services/export_service.dart';
import '../services/pdf_generator_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({Key? key}) : super(key: key);

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  final _pdfService = PdfGeneratorService();
  
  String _exportType = 'loads';
  String _format = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  
  final _dateFormat = DateFormat('MMM dd, yyyy');
  
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
  
  Future<void> _performExport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }
    
    setState(() => _isExporting = true);
    
    try {
      switch (_exportType) {
        case 'loads':
          await _exportLoads();
          break;
        case 'invoices':
          await _exportInvoices();
          break;
        case 'earnings':
          await _exportEarnings();
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export completed successfully')),
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
  
  Future<void> _exportLoads() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('loads')
        .where('createdAt', isGreaterThanOrEqualTo: _startDate!.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: _endDate!.toIso8601String())
        .get();
    
    final loads = snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
    
    if (loads.isEmpty) {
      throw Exception('No data found for the selected date range');
    }
    
    final file = _format == 'csv'
        ? await _exportService.exportLoadsToCSV(loads: loads)
        : await _pdfService.generateLoadReportPDF(
            loads: loads,
            startDate: _startDate,
            endDate: _endDate,
          );
    
    await _exportService.shareFile(file);
  }
  
  Future<void> _exportInvoices() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('invoices')
        .where('invoiceDate', isGreaterThanOrEqualTo: _startDate!.toIso8601String())
        .where('invoiceDate', isLessThanOrEqualTo: _endDate!.toIso8601String())
        .get();
    
    final invoices = snapshot.docs.map((doc) => Invoice.fromDoc(doc)).toList();
    
    if (invoices.isEmpty) {
      throw Exception('No invoices found for the selected date range');
    }
    
    if (_format == 'csv') {
      final file = await _exportService.exportInvoicesToCSV(invoices: invoices);
      await _exportService.shareFile(file);
    } else {
      throw Exception('PDF format not available for invoice list. Use Invoice Management to export individual invoices.');
    }
  }
  
  Future<void> _exportEarnings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('loads')
        .where('createdAt', isGreaterThanOrEqualTo: _startDate!.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: _endDate!.toIso8601String())
        .where('status', isEqualTo: 'delivered')
        .get();
    
    final loads = snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
    
    if (loads.isEmpty) {
      throw Exception('No earnings data found for the selected date range');
    }
    
    final driverLoads = <String, List<LoadModel>>{};
    for (final load in loads) {
      final driverName = load.driverName ?? 'Unknown';
      driverLoads.putIfAbsent(driverName, () => []).add(load);
    }
    
    final file = _format == 'csv'
        ? await _exportService.exportDriverEarningsToCSV(driverLoads: driverLoads)
        : await _pdfService.generateEarningsReportPDF(
            driverLoads: driverLoads,
            startDate: _startDate,
            endDate: _endDate,
          );
    
    await _exportService.shareFile(file);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'loads',
                  label: Text('Loads'),
                  icon: Icon(Icons.local_shipping),
                ),
                ButtonSegment(
                  value: 'invoices',
                  label: Text('Invoices'),
                  icon: Icon(Icons.receipt),
                ),
                ButtonSegment(
                  value: 'earnings',
                  label: Text('Earnings'),
                  icon: Icon(Icons.attach_money),
                ),
              ],
              selected: {_exportType},
              onSelectionChanged: (Set<String> selected) {
                setState(() => _exportType = selected.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Format',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'csv',
                  label: Text('CSV'),
                  icon: Icon(Icons.table_chart),
                ),
                ButtonSegment(
                  value: 'pdf',
                  label: Text('PDF'),
                  icon: Icon(Icons.picture_as_pdf),
                ),
              ],
              selected: {_format},
              onSelectionChanged: (Set<String> selected) {
                setState(() => _format = selected.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                _startDate != null && _endDate != null
                    ? '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}'
                    : 'Select Date Range',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isExporting ? null : _performExport,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Export'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Export History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildExportHistory(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExportHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.history, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Export history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
