import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import 'package:intl/intl.dart';

/// Export Screen - Export data to CSV/PDF
/// 
/// Export options:
/// - Loads (CSV)
/// - Expenses (CSV)
/// - Earnings (CSV)
/// - Driver Performance (CSV)
/// - Custom date range selection
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    AnalyticsService.instance.logScreenView(screenName: 'export');
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportData(String exportType) async {
    setState(() => _isExporting = true);

    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));

      await AnalyticsService.instance.logEvent('data_exported', parameters: {
        'export_type': exportType,
        'start_date': _startDate?.toIso8601String() ?? '',
        'end_date': _endDate?.toIso8601String() ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$exportType exported successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open exported file
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateRangeText = _startDate != null && _endDate != null
        ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
        : 'Select date range';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Export your data to CSV or PDF format for record keeping and analysis.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Date Range Selection
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Select Date Range'),
              subtitle: Text(dateRangeText),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDateRange,
            ),
          ),

          const SizedBox(height: 32),

          // Export Options
          const Text(
            'Export Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _buildExportOption(
            title: 'Load Report',
            subtitle: 'Export all loads with details',
            icon: Icons.assignment,
            color: Colors.blue,
            exportType: 'Loads',
          ),

          _buildExportOption(
            title: 'Earnings Report',
            subtitle: 'Export earnings breakdown',
            icon: Icons.attach_money,
            color: Colors.green,
            exportType: 'Earnings',
          ),

          _buildExportOption(
            title: 'Expenses Report',
            subtitle: 'Export all expenses',
            icon: Icons.receipt_long,
            color: Colors.orange,
            exportType: 'Expenses',
          ),

          _buildExportOption(
            title: 'Driver Performance',
            subtitle: 'Export driver statistics',
            icon: Icons.bar_chart,
            color: Colors.purple,
            exportType: 'Driver Performance',
          ),

          _buildExportOption(
            title: 'Complete Report',
            subtitle: 'Export all data (PDF)',
            icon: Icons.picture_as_pdf,
            color: Colors.red,
            exportType: 'Complete Report',
          ),

          const SizedBox(height: 32),

          // Export All Button
          ElevatedButton.icon(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download),
            label: const Text('Export All Data'),
            onPressed: _isExporting ? null : () => _exportData('All Data'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Info Text
          Text(
            'Exported files will be saved to your Downloads folder',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String exportType,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _isExporting ? null : () => _exportData(exportType),
        ),
      ),
    );
  }
}
