import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';

/// PDF Generation Service - Generate PDF documents
/// 
/// Handles:
/// - Invoice PDF generation
/// - Report PDF generation
/// - Custom PDF layouts
class PDFGenerationService {
  static final PDFGenerationService _instance = PDFGenerationService._internal();
  factory PDFGenerationService() => _instance;
  static PDFGenerationService get instance => _instance;
  PDFGenerationService._internal();

  /// Generate invoice PDF
  Future<File> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with company info
            _buildHeader(invoice.companyInfo),
            pw.SizedBox(height: 20),

            // Invoice details
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 20),

            // Client info
            _buildClientInfo(invoice.clientInfo),
            pw.SizedBox(height: 20),

            // Line items table
            _buildLineItemsTable(invoice.lineItems),
            pw.SizedBox(height: 20),

            // Totals
            _buildTotals(invoice),

            // Notes
            if (invoice.notes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildNotes(invoice.notes),
            ],
          ],
        ),
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build header section
  pw.Widget _buildHeader(CompanyInfo companyInfo) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          companyInfo.name,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('${companyInfo.address}'),
        pw.Text('${companyInfo.city}, ${companyInfo.state} ${companyInfo.zipCode}'),
        pw.Text('Phone: ${companyInfo.phone}'),
        pw.Text('Email: ${companyInfo.email}'),
      ],
    );
  }

  /// Build invoice details section
  pw.Widget _buildInvoiceDetails(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Invoice #: ${invoice.invoiceNumber}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Issue Date: ${_formatDate(invoice.issueDate)}'),
            pw.Text('Due Date: ${_formatDate(invoice.dueDate)}'),
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: _getStatusColor(invoice.status),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                invoice.status.toUpperCase(),
                style: const pw.TextStyle(color: PdfColors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build client info section
  pw.Widget _buildClientInfo(ClientInfo clientInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(clientInfo.name),
          pw.Text('${clientInfo.address}'),
          pw.Text('${clientInfo.city}, ${clientInfo.state} ${clientInfo.zipCode}'),
          pw.Text('Phone: ${clientInfo.phone}'),
          pw.Text('Email: ${clientInfo.email}'),
        ],
      ),
    );
  }

  /// Build line items table
  pw.Widget _buildLineItemsTable(List<LineItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Quantity', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data rows
        ...items.map(
          (item) => pw.TableRow(
            children: [
              _buildTableCell(item.description),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('\$${item.unitPrice.toStringAsFixed(2)}'),
              _buildTableCell('\$${item.total.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build totals section
  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal:', '\$${invoice.subtotal.toStringAsFixed(2)}'),
            _buildTotalRow('Tax:', '\$${invoice.tax.toStringAsFixed(2)}'),
            pw.Divider(),
            _buildTotalRow(
              'Total:',
              '\$${invoice.total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Build notes section
  pw.Widget _buildNotes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(notes),
      ],
    );
  }

  /// Helper: Build table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Helper: Build total row
  pw.Widget _buildTotalRow(String label, String value, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 16 : 12,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: isTotal ? 16 : 12,
          ),
        ),
      ],
    );
  }

  /// Helper: Format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  /// Helper: Get status color
  PdfColor _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PdfColors.green;
      case 'sent':
        return PdfColors.blue;
      case 'draft':
        return PdfColors.orange;
      default:
        return PdfColors.grey;
    }
  }

  /// Generate report PDF (placeholder)
  Future<File> generateReportPDF({
    required String title,
    required List<String> content,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            ...content.map((line) => pw.Text(line)),
          ],
        ),
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
