import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/load.dart';
import '../models/invoice.dart';
import '../utils/pdf_generator.dart';

class PdfGeneratorService {
  Future<String> _getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }
  
  Future<File> generateLoadReportPDF({
    required List<LoadModel> loads,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    
    final dateRange = startDate != null && endDate != null
        ? '${PdfGenerator.formatDate(startDate)} - ${PdfGenerator.formatDate(endDate)}'
        : 'All Time';
    
    final totalRevenue = loads.fold(0.0, (sum, load) => sum + load.rate);
    final totalMiles = loads.fold(0.0, (sum, load) => sum + load.miles);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfGenerator.buildHeader(
                'Load Report',
                subtitle: dateRange,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Total Loads', loads.length.toString()),
                  _buildSummaryCard('Total Revenue', PdfGenerator.formatCurrency(totalRevenue)),
                  _buildSummaryCard('Total Miles', totalMiles.toStringAsFixed(0)),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Load Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              PdfGenerator.buildTable(
                headers: ['Load #', 'Driver', 'Pickup', 'Delivery', 'Miles', 'Rate', 'Status'],
                rows: loads.map((load) => [
                  load.loadNumber,
                  load.driverName ?? 'N/A',
                  _truncate(load.pickupAddress, 20),
                  _truncate(load.deliveryAddress, 20),
                  load.miles.toStringAsFixed(0),
                  PdfGenerator.formatCurrency(load.rate),
                  load.status,
                ]).toList(),
                columnWidths: [1.2, 1.2, 1.5, 1.5, 0.8, 1, 1],
              ),
            ],
          );
        },
      ),
    );
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'load_report_$timestamp.pdf';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  Future<File> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return PdfGenerator.buildInvoiceTemplate(
            invoiceNumber: invoice.invoiceNumber,
            invoiceDate: invoice.invoiceDate,
            dueDate: invoice.dueDate,
            customerName: invoice.customerName,
            customerAddress: invoice.customerAddress,
            lineItems: invoice.lineItems.map((item) => {
              'description': item.description,
              'quantity': item.quantity,
              'rate': item.rate,
              'amount': item.amount,
            }).toList(),
            subtotal: invoice.subtotal,
            tax: invoice.tax,
            total: invoice.total,
            notes: invoice.notes,
          );
        },
      ),
    );
    
    final filename = '${invoice.invoiceNumber.replaceAll('/', '_')}.pdf';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  Future<File> generateEarningsReportPDF({
    required Map<String, List<LoadModel>> driverLoads,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    
    final dateRange = startDate != null && endDate != null
        ? '${PdfGenerator.formatDate(startDate)} - ${PdfGenerator.formatDate(endDate)}'
        : 'All Time';
    
    final totalLoads = driverLoads.values.fold(0, (sum, loads) => sum + loads.length);
    final totalEarnings = driverLoads.values
        .expand((loads) => loads)
        .fold(0.0, (sum, load) => sum + load.rate);
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              PdfGenerator.buildHeader(
                'Driver Earnings Report',
                subtitle: dateRange,
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Total Drivers', driverLoads.length.toString()),
                  _buildSummaryCard('Total Loads', totalLoads.toString()),
                  _buildSummaryCard('Total Earnings', PdfGenerator.formatCurrency(totalEarnings)),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Driver Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              PdfGenerator.buildTable(
                headers: ['Driver', 'Loads', 'Miles', 'Earnings', 'Avg/Load'],
                rows: driverLoads.entries.map((entry) {
                  final loads = entry.value;
                  final totalMiles = loads.fold(0.0, (sum, l) => sum + l.miles);
                  final earnings = loads.fold(0.0, (sum, l) => sum + l.rate);
                  final avgPerLoad = loads.isNotEmpty ? earnings / loads.length : 0.0;
                  
                  return [
                    entry.key,
                    loads.length.toString(),
                    totalMiles.toStringAsFixed(0),
                    PdfGenerator.formatCurrency(earnings),
                    PdfGenerator.formatCurrency(avgPerLoad),
                  ];
                }).toList(),
                columnWidths: [2, 1, 1, 1.5, 1.5],
              ),
            ],
          );
        },
      ),
    );
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'earnings_report_$timestamp.pdf';
    final directory = await _getExportDirectory();
    final file = File('$directory/$filename');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  pw.Widget _buildSummaryCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}
