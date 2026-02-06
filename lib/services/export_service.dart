import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../models/load.dart';
import '../models/expense.dart';
import '../services/mock_data_service.dart';
import '../services/expense_service.dart';

/// Export Service - Export data to CSV format
/// 
/// Handles:
/// - Exporting loads to CSV
/// - Exporting expenses to CSV
/// - Exporting driver performance to CSV
/// - Saving files to device storage
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  static ExportService get instance => _instance;
  ExportService._internal();

  final MockDataService _mockService = MockDataService();
  final ExpenseService _expenseService = ExpenseService();

  /// Export loads to CSV
  Future<File> exportLoadsToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get loads from service
    final loads = await _mockService.getAllLoads();
    
    // Filter by date if provided
    final filteredLoads = loads.where((load) {
      if (startDate != null && load.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && load.createdAt.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();

    // Generate CSV
    final csv = _generateLoadCSV(filteredLoads);
    
    // Save to file
    return await _saveToFile(csv, 'loads_export.csv');
  }

  /// Export expenses to CSV
  Future<File> exportExpensesToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get expenses from service - get all at once from stream
    final expensesList = await _expenseService.streamAllExpenses().first;
    
    // Filter by date if provided
    final filteredExpenses = expensesList.where((expense) {
      if (startDate != null && expense.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expense.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();

    // Generate CSV
    final csv = _generateExpenseCSV(filteredExpenses);
    
    // Save to file
    return await _saveToFile(csv, 'expenses_export.csv');
  }

  /// Export driver performance to CSV
  Future<File> exportDriverPerformanceToCSV(String driverId) async {
    // Get driver loads
    final loads = await _mockService.getDriverLoads(driverId);
    
    // Calculate statistics
    final totalLoads = loads.length;
    final completedLoads = loads.where((l) => l.status == 'delivered').length;
    final totalEarnings = loads.fold<double>(
      0,
      (sum, load) => sum + load.rate,
    );

    // Generate CSV with statistics
    final data = [
      ['Metric', 'Value'],
      ['Total Loads', totalLoads.toString()],
      ['Completed Loads', completedLoads.toString()],
      ['Completion Rate', '${(completedLoads / totalLoads * 100).toStringAsFixed(1)}%'],
      ['Total Earnings', '\$${totalEarnings.toStringAsFixed(2)}'],
      ['Average per Load', '\$${(totalEarnings / totalLoads).toStringAsFixed(2)}'],
    ];

    final csv = const ListToCsvConverter().convert(data);
    return await _saveToFile(csv, 'driver_performance.csv');
  }

  /// Generate CSV from loads
  String _generateLoadCSV(List<LoadModel> loads) {
    // CSV headers
    final data = [
      [
        'Load Number',
        'Driver ID',
        'Pickup Address',
        'Delivery Address',
        'Rate',
        'Status',
        'Created Date',
      ],
    ];

    // Add load data
    for (final load in loads) {
      data.add([
        load.loadNumber,
        load.driverId,
        load.pickupAddress,
        load.deliveryAddress,
        '\$${load.rate.toStringAsFixed(2)}',
        load.status,
        load.createdAt.toIso8601String(),
      ]);
    }

    return const ListToCsvConverter().convert(data);
  }

  /// Generate CSV from expenses
  String _generateExpenseCSV(List<Expense> expenses) {
    // CSV headers
    final data = [
      [
        'Description',
        'Amount',
        'Category',
        'Date',
        'Receipt',
      ],
    ];

    // Add expense data
    for (final expense in expenses) {
      data.add([
        expense.description,
        '\$${expense.amount.toStringAsFixed(2)}',
        expense.category,
        expense.date.toIso8601String(),
        expense.receiptUrl ?? 'N/A',
      ]);
    }

    return const ListToCsvConverter().convert(data);
  }

  /// Save CSV string to file
  Future<File> _saveToFile(String csv, String filename) async {
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    
    // Create file
    final file = File('${directory.path}/$filename');
    
    // Write CSV data
    await file.writeAsString(csv);
    
    return file;
  }

  /// Get all exports as a ZIP file (placeholder)
  Future<File> exportAllData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // TODO: Implement ZIP file creation with multiple CSVs
    // For now, just export loads
    return await exportLoadsToCSV(startDate: startDate, endDate: endDate);
  }
}
