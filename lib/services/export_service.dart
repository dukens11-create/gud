import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/load.dart';
import '../models/expense.dart';

/// Service for exporting data to CSV format
class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Export loads to CSV file with date filtering
  /// Returns the file path for sharing
  Future<String> exportLoadsToCSV(DateTime start, DateTime end) async {
    try {
      // Query loads within date range
      final snapshot = await _firestore
          .collection('loads')
          .where('createdAt',
              isGreaterThanOrEqualTo: start.toIso8601String())
          .where('createdAt', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('createdAt', descending: true)
          .get();

      // Convert to LoadModel objects
      final loads = snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();

      // Create CSV data
      List<List<dynamic>> rows = [
        [
          'Load Number',
          'Driver Name',
          'Pickup Address',
          'Delivery Address',
          'Rate',
          'Miles',
          'Status',
          'Created At',
          'Picked Up At',
          'Delivered At',
          'Notes',
        ],
      ];

      for (var load in loads) {
        rows.add([
          load.loadNumber,
          load.driverName ?? 'N/A',
          load.pickupAddress,
          load.deliveryAddress,
          load.rate.toStringAsFixed(2),
          load.miles.toStringAsFixed(1),
          load.status,
          _dateFormat.format(load.createdAt),
          load.pickedUpAt != null ? _dateFormat.format(load.pickedUpAt!) : '',
          load.deliveredAt != null
              ? _dateFormat.format(load.deliveredAt!)
              : '',
          load.notes ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'loads_export_${_fileNameFormat.format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export loads to CSV: $e');
    }
  }

  /// Export expenses to CSV file with date filtering
  /// Returns the file path for sharing
  Future<String> exportExpensesToCSV(DateTime start, DateTime end) async {
    try {
      // Query expenses within date range
      final snapshot = await _firestore
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      // Convert to Expense objects
      final expenses =
          snapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();

      // Create CSV data
      List<List<dynamic>> rows = [
        [
          'Date',
          'Category',
          'Description',
          'Amount',
          'Driver ID',
          'Load ID',
          'Created By',
        ],
      ];

      for (var expense in expenses) {
        rows.add([
          _dateFormat.format(expense.date),
          expense.category,
          expense.description,
          expense.amount.toStringAsFixed(2),
          expense.driverId ?? '',
          expense.loadId ?? '',
          expense.createdBy,
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'expenses_export_${_fileNameFormat.format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export expenses to CSV: $e');
    }
  }

  /// Export driver performance to CSV file
  /// Returns the file path for sharing
  Future<String> exportDriverPerformanceToCSV(String driverId) async {
    try {
      // Query all loads for this driver
      final loadsSnapshot = await _firestore
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();

      final loads =
          loadsSnapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();

      // Query all expenses for this driver
      final expensesSnapshot = await _firestore
          .collection('expenses')
          .where('driverId', isEqualTo: driverId)
          .orderBy('date', descending: true)
          .get();

      final expenses =
          expensesSnapshot.docs.map((doc) => Expense.fromDoc(doc)).toList();

      // Calculate statistics
      final totalLoads = loads.length;
      final deliveredLoads =
          loads.where((l) => l.status == 'delivered').length;
      final totalRevenue = loads.fold<double>(0.0, (sum, l) => sum + l.rate);
      final totalMiles = loads.fold<double>(0.0, (sum, l) => sum + l.miles);
      final totalExpenses =
          expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      final netRevenue = totalRevenue - totalExpenses;

      // Create CSV data
      List<List<dynamic>> rows = [
        ['Driver Performance Report'],
        ['Driver ID:', driverId],
        ['Generated:', _dateFormat.format(DateTime.now())],
        [],
        ['Summary Statistics'],
        ['Total Loads', totalLoads],
        ['Delivered Loads', deliveredLoads],
        ['Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}'],
        ['Total Miles', totalMiles.toStringAsFixed(1)],
        ['Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}'],
        ['Net Revenue', '\$${netRevenue.toStringAsFixed(2)}'],
        [
          'Revenue per Mile',
          totalMiles > 0
              ? '\$${(totalRevenue / totalMiles).toStringAsFixed(2)}'
              : 'N/A'
        ],
        [],
        ['Recent Loads'],
        [
          'Load Number',
          'Pickup',
          'Delivery',
          'Rate',
          'Miles',
          'Status',
          'Created'
        ],
      ];

      // Add recent loads (limit to 50)
      for (var load in loads.take(50)) {
        rows.add([
          load.loadNumber,
          load.pickupAddress,
          load.deliveryAddress,
          '\$${load.rate.toStringAsFixed(2)}',
          load.miles.toStringAsFixed(1),
          load.status,
          _dateFormat.format(load.createdAt),
        ]);
      }

      rows.add([]);
      rows.add(['Recent Expenses']);
      rows.add(['Date', 'Category', 'Description', 'Amount']);

      // Add recent expenses (limit to 50)
      for (var expense in expenses.take(50)) {
        rows.add([
          _dateFormat.format(expense.date),
          expense.category,
          expense.description,
          '\$${expense.amount.toStringAsFixed(2)}',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(rows);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'driver_performance_${driverId}_${_fileNameFormat.format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export driver performance to CSV: $e');
    }
  }

  /// Export all loads to CSV (no date filter)
  Future<String> exportAllLoadsToCSV() async {
    final now = DateTime.now();
    final start = DateTime(2020, 1, 1); // Far back in time
    return exportLoadsToCSV(start, now);
  }

  /// Export all expenses to CSV (no date filter)
  Future<String> exportAllExpensesToCSV() async {
    final now = DateTime.now();
    final start = DateTime(2020, 1, 1); // Far back in time
    return exportExpensesToCSV(start, now);
  }
}
