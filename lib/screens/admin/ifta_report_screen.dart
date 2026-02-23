import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../services/ifta_service.dart';
import '../../services/firestore_service.dart';
import '../../models/driver.dart';

/// Admin-only screen for viewing IFTA (International Fuel Tax Agreement) reports.
/// Shows total miles driven and total gallons of fuel purchased per driver
/// for a selected date range.
class IftaReportScreen extends StatefulWidget {
  const IftaReportScreen({super.key});

  @override
  State<IftaReportScreen> createState() => _IftaReportScreenState();
}

class _IftaReportScreenState extends State<IftaReportScreen> {
  final _iftaService = IftaService();
  final _firestoreService = FirestoreService();

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String? _selectedDriverId;

  List<IftaDriverSummary>? _results;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _iftaService.getReport(
        startDate: _startDate,
        endDate: _endDate,
        driverId: _selectedDriverId,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReport();
    }
  }

  Future<void> _exportCsv() async {
    final rows = _results;
    if (rows == null || rows.isEmpty) return;

    final buf = StringBuffer();
    buf.writeln('Driver ID,Driver Name,Total Miles,Total Gallons,MPG');
    for (final row in rows) {
      final name = (row.driverName ?? '').replaceAll(',', ' ');
      buf.writeln(
        '${row.driverId},$name,'
        '${row.totalMiles.toStringAsFixed(2)},'
        '${row.totalGallons.toStringAsFixed(3)},'
        '${row.mpg.toStringAsFixed(2)}',
      );
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ifta_report.csv');
      await file.writeAsString(buf.toString(), encoding: utf8);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'IFTA Report',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('IFTA Report'),
        actions: [
          if (_results != null && _results!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: _exportCsv,
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filters ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range row
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${dateFormat.format(_startDate)} – ${dateFormat.format(_endDate)}',
                  ),
                  onPressed: _pickDateRange,
                ),
                const SizedBox(height: 12),
                // Driver selector
                StreamBuilder<List<Driver>>(
                  stream: _firestoreService.streamDrivers(),
                  builder: (context, snapshot) {
                    final drivers = snapshot.data ?? [];
                    return DropdownButtonFormField<String?>(
                      value: _selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Driver (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All drivers')),
                        ...drivers.map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDriverId = value);
                        _loadReport();
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Results ───────────────────────────────────────────────────────
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text('Error: $_error',
                    style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (_results == null || _results!.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_gas_station,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No IFTA data for selected range',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Driver')),
                      DataColumn(
                          label: Text('Miles'),
                          numeric: true),
                      DataColumn(
                          label: Text('Gallons'),
                          numeric: true),
                      DataColumn(
                          label: Text('MPG'),
                          numeric: true),
                    ],
                    rows: [
                      ..._results!.map((row) => DataRow(cells: [
                            DataCell(Text(
                                row.driverName ?? row.driverId,
                                overflow: TextOverflow.ellipsis)),
                            DataCell(Text(
                                row.totalMiles.toStringAsFixed(1))),
                            DataCell(Text(
                                row.totalGallons.toStringAsFixed(3))),
                            DataCell(Text(
                                row.mpg > 0
                                    ? row.mpg.toStringAsFixed(2)
                                    : '—')),
                          ])),
                      // Totals row
                      DataRow(
                        color: WidgetStateProperty.all(
                            Theme.of(context)
                                .primaryColor
                                .withOpacity(0.08)),
                        cells: [
                          const DataCell(Text('Total',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold))),
                          DataCell(Text(
                            _results!
                                .fold<double>(
                                    0, (s, r) => s + r.totalMiles)
                                .toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          )),
                          DataCell(Text(
                            _results!
                                .fold<double>(
                                    0, (s, r) => s + r.totalGallons)
                                .toStringAsFixed(3),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          )),
                          const DataCell(Text('—')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
