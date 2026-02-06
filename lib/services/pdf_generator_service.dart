import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/load.dart';
import '../models/invoice.dart';

/// Service for generating PDF documents
class PDFGeneratorService {
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  final DateFormat _fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Generate PDF report for loads
  /// Returns the File object for sharing
  Future<File> generateLoadReport(List<LoadModel> loads) async {
    final pdf = pw.Document();

    // Calculate summary statistics
    final totalLoads = loads.length;
    final deliveredLoads = loads.where((l) => l.status == 'delivered').length;
    final totalRevenue = loads.fold<double>(0.0, (sum, l) => sum + l.rate);
    final totalMiles = loads.fold<double>(0.0, (sum, l) => sum + l.miles);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Load Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Generated: ${_dateTimeFormat.format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),

          // Summary section
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Summary',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Loads: $totalLoads'),
                    pw.Text('Delivered: $deliveredLoads'),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Revenue: \$${totalRevenue.toStringAsFixed(2)}'),
                    pw.Text('Total Miles: ${totalMiles.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
          ),

          // Loads table
          pw.SizedBox(height: 20),
          pw.Text('Load Details',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildLoadsTable(loads),
        ],
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'load_report_${_fileNameFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build loads table for PDF
  pw.Widget _buildLoadsTable(List<LoadModel> loads) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Load #', isHeader: true),
            _tableCell('Pickup', isHeader: true),
            _tableCell('Delivery', isHeader: true),
            _tableCell('Rate', isHeader: true),
            _tableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...loads.map((load) => pw.TableRow(
              children: [
                _tableCell(load.loadNumber),
                _tableCell(load.pickupAddress),
                _tableCell(load.deliveryAddress),
                _tableCell('\$${load.rate.toStringAsFixed(2)}'),
                _tableCell(load.status),
              ],
            )),
      ],
    );
  }

  /// Helper to create table cell
  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Generate PDF invoice
  /// Returns the File object for sharing
  Future<File> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with company info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                            fontSize: 32, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.invoiceNumber,
                        style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(invoice.companyInfo.name,
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.companyInfo.address,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        '${invoice.companyInfo.city}, ${invoice.companyInfo.state} ${invoice.companyInfo.zip}',
                        style: const pw.TextStyle(fontSize: 10)),
                    if (invoice.companyInfo.phone != null)
                      pw.Text(invoice.companyInfo.phone!,
                          style: const pw.TextStyle(fontSize: 10)),
                    if (invoice.companyInfo.email != null)
                      pw.Text(invoice.companyInfo.email!,
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Invoice details and client info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Client info
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(invoice.clientInfo.name,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.clientInfo.address,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        '${invoice.clientInfo.city}, ${invoice.clientInfo.state} ${invoice.clientInfo.zip}',
                        style: const pw.TextStyle(fontSize: 10)),
                    if (invoice.clientInfo.phone != null)
                      pw.Text(invoice.clientInfo.phone!,
                          style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                // Invoice details
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Issue Date: ${_dateFormat.format(invoice.issueDate)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Due Date: ${_dateFormat.format(invoice.dueDate)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Status: ${invoice.status.name.toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Line items table
            _buildInvoiceItemsTable(invoice.lineItems),

            pw.SizedBox(height: 20),

            // Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    _totalRow('Subtotal:', invoice.subtotal),
                    _totalRow('Tax:', invoice.tax),
                    pw.Divider(thickness: 2),
                    _totalRow('TOTAL:', invoice.total, isBold: true),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Notes
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.Text('Notes',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.notes!, style: const pw.TextStyle(fontSize: 10)),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.Center(
              child: pw.Text('Thank you for your business!',
                  style: pw.TextStyle(
                      fontSize: 10, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'invoice_${invoice.invoiceNumber}_${_fileNameFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Build invoice items table
  pw.Widget _buildInvoiceItemsTable(List<InvoiceLineItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Description', isHeader: true),
            _tableCell('Qty', isHeader: true),
            _tableCell('Unit Price', isHeader: true),
            _tableCell('Amount', isHeader: true),
          ],
        ),
        // Items
        ...items.map((item) => pw.TableRow(
              children: [
                _tableCell(item.description),
                _tableCell(item.quantity.toStringAsFixed(0)),
                _tableCell('\$${item.unitPrice.toStringAsFixed(2)}'),
                _tableCell('\$${item.amount.toStringAsFixed(2)}'),
              ],
            )),
      ],
    );
  }

  /// Helper to create total row
  pw.Widget _totalRow(String label, double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Container(
            width: 80,
            child: pw.Text(
              '\$${amount.toStringAsFixed(2)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate monthly report PDF
  /// Returns the File object for sharing
  Future<File> generateMonthlyReport(int year, int month) async {
    // This is a placeholder implementation
    // In a real app, you would query loads and expenses for the month
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text('Monthly Report - $monthName',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Generated: ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 30),
            pw.Text('Summary statistics would go here',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
            pw.Text('Detailed breakdown would follow',
                style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'monthly_report_${year}_${month.toString().padLeft(2, '0')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
