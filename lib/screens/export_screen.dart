import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/export_service.dart';
import '../services/pdf_generator_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  final _pdfService = PDFGeneratorService();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedFormat = 'CSV';
  bool _isExporting = false;

  Future<void> _selectDateRange() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _exportLoadReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      if (_selectedFormat == 'CSV') {
        final filePath = await _exportService.exportLoadsToCSV(_startDate!, _endDate!);
        _showSuccessAndShare(filePath);
      } else {
        // PDF export would need to fetch loads first
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF export for loads - please use Load History screen'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExpenseReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await _exportService.exportExpensesToCSV(_startDate!, _endDate!);
      _showSuccessAndShare(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDriverPerformance() async {
    // For now, show a dialog to enter driver ID
    final driverIdController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Driver Performance Report'),
        content: TextField(
          controller: driverIdController,
          decoration: const InputDecoration(
            labelText: 'Driver ID',
            hintText: 'Enter driver ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(driverIdController.text),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final filePath = await _exportService.exportDriverPerformanceToCSV(result);
      _showSuccessAndShare(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFinancialSummary() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range first')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Export both loads and expenses
      final loadsPath = await _exportService.exportLoadsToCSV(_startDate!, _endDate!);
      final expensesPath = await _exportService.exportExpensesToCSV(_startDate!, _endDate!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Financial reports exported:\n$loadsPath\n$expensesPath'),
            duration: const Duration(seconds: 4),
          ),
        );

        // Share both files
        await Share.shareXFiles(
          [XFile(loadsPath), XFile(expensesPath)],
          text: 'Financial Summary Report',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSuccessAndShare(String filePath) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export saved: $filePath'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            Share.shareXFiles([XFile(filePath)]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date range selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(
                        _startDate != null && _endDate != null
                            ? '${_dateFormat.format(_startDate!)} - ${_dateFormat.format(_endDate!)}'
                            : 'Select date range',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _selectDateRange,
                      tileColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Format selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('CSV'),
                            value: 'CSV',
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFormat = value);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('PDF'),
                            value: 'PDF',
                            groupValue: _selectedFormat,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedFormat = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export options heading
            const Text(
              'Export Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Export option cards
            _buildExportOptionCard(
              title: 'Load Reports',
              description: 'Export all loads with pickup, delivery, and status',
              icon: Icons.local_shipping,
              color: Colors.blue,
              onTap: _exportLoadReport,
            ),
            const SizedBox(height: 12),

            _buildExportOptionCard(
              title: 'Expense Reports',
              description: 'Export all expenses by category and date',
              icon: Icons.receipt_long,
              color: Colors.red,
              onTap: _exportExpenseReport,
            ),
            const SizedBox(height: 12),

            _buildExportOptionCard(
              title: 'Driver Performance',
              description: 'Export driver statistics and load history',
              icon: Icons.person,
              color: Colors.green,
              onTap: _exportDriverPerformance,
            ),
            const SizedBox(height: 12),

            _buildExportOptionCard(
              title: 'Financial Summary',
              description: 'Export comprehensive financial report',
              icon: Icons.attach_money,
              color: Colors.orange,
              onTap: _exportFinancialSummary,
            ),

            if (_isExporting) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
