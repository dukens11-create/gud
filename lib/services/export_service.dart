import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/load.dart';
import '../models/invoice.dart';
import '../utils/csv_exporter.dart';

class ExportService {
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  final _dateFormat = DateFormat('yyyy-MM-dd');
  
  Future<String> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }
  
  Future<File> exportLoadsToCSV({
    required List<LoadModel> loads,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? fields,
  }) async {
    final headers = fields ?? [
      'Load Number',
      'Driver',
      'Pickup Address',
      'Delivery Address',
      'Rate',
      'Miles',
      'Status',
      'Created Date',
      'Delivered Date',
    ];
    
    final rows = loads.map((load) {
      final data = <String, dynamic>{
        'Load Number': load.loadNumber,
        'Driver': load.driverName ?? 'N/A',
        'Pickup Address': load.pickupAddress,
        'Delivery Address': load.deliveryAddress,
        'Rate': _currencyFormat.format(load.rate),
        'Miles': load.miles.toStringAsFixed(1),
        'Status': load.status,
        'Created Date': _dateFormat.format(load.createdAt),
        'Delivered Date': load.deliveredAt != null 
            ? _dateFormat.format(load.deliveredAt!) 
            : 'N/A',
      };
      return data;
    }).toList();
    
    final csv = CsvExporter.mapListToCSV(rows, headers);
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'loads_export_$timestamp.csv';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsString(csv);
    return file;
  }
  
  Future<File> exportInvoicesToCSV({
    required List<Invoice> invoices,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = [
      'Invoice Number',
      'Customer Name',
      'Invoice Date',
      'Due Date',
      'Subtotal',
      'Tax',
      'Total',
      'Amount Paid',
      'Balance',
      'Status',
    ];
    
    final rows = invoices.map((invoice) {
      return <String, dynamic>{
        'Invoice Number': invoice.invoiceNumber,
        'Customer Name': invoice.customerName,
        'Invoice Date': _dateFormat.format(invoice.invoiceDate),
        'Due Date': _dateFormat.format(invoice.dueDate),
        'Subtotal': _currencyFormat.format(invoice.subtotal),
        'Tax': _currencyFormat.format(invoice.tax),
        'Total': _currencyFormat.format(invoice.total),
        'Amount Paid': _currencyFormat.format(invoice.amountPaid),
        'Balance': _currencyFormat.format(invoice.balance),
        'Status': invoice.status,
      };
    }).toList();
    
    final csv = CsvExporter.mapListToCSV(rows, headers);
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'invoices_export_$timestamp.csv';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsString(csv);
    return file;
  }
  
  Future<File> exportDriverEarningsToCSV({
    required Map<String, List<LoadModel>> driverLoads,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final headers = [
      'Driver Name',
      'Total Loads',
      'Total Miles',
      'Total Earnings',
      'Average Per Load',
      'Average Per Mile',
    ];
    
    final rows = driverLoads.entries.map((entry) {
      final driverName = entry.key;
      final loads = entry.value;
      final totalLoads = loads.length;
      final totalMiles = loads.fold(0.0, (sum, load) => sum + load.miles);
      final totalEarnings = loads.fold(0.0, (sum, load) => sum + load.rate);
      final avgPerLoad = totalLoads > 0 ? totalEarnings / totalLoads : 0.0;
      final avgPerMile = totalMiles > 0 ? totalEarnings / totalMiles : 0.0;
      
      return <String, dynamic>{
        'Driver Name': driverName,
        'Total Loads': totalLoads.toString(),
        'Total Miles': totalMiles.toStringAsFixed(1),
        'Total Earnings': _currencyFormat.format(totalEarnings),
        'Average Per Load': _currencyFormat.format(avgPerLoad),
        'Average Per Mile': _currencyFormat.format(avgPerMile),
      };
    }).toList();
    
    final csv = CsvExporter.mapListToCSV(rows, headers);
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'driver_earnings_$timestamp.csv';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsString(csv);
    return file;
  }
  
  Future<void> shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Export: ${file.path.split('/').last}',
    );
  }
  
  List<LoadModel> filterLoadsByDateRange({
    required List<LoadModel> loads,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) return loads;
    
    return loads.where((load) {
      if (startDate != null && load.createdAt.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && load.createdAt.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }
  
  List<Invoice> filterInvoicesByDateRange({
    required List<Invoice> invoices,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) return invoices;
    
    return invoices.where((invoice) {
      if (startDate != null && invoice.invoiceDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && invoice.invoiceDate.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }
}
