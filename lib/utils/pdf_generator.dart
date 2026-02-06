import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfGenerator {
  static final _currencyFormat = NumberFormat.currency(symbol: '\$');
  static final _dateFormat = DateFormat('MMM dd, yyyy');
  static final _dateTimeFormat = DateFormat('MMM dd, yyyy HH:mm');
  
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }
  
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  static pw.Widget buildHeader(String title, {String? subtitle}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Divider(),
      ],
    );
  }
  
  static pw.Widget buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    List<double>? columnWidths,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: columnWidths != null
          ? Map.fromIterables(
              List.generate(columnWidths.length, (i) => i),
              columnWidths.map((w) => pw.FlexColumnWidth(w)),
            )
          : null,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              header,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          )).toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              cell,
              style: const pw.TextStyle(fontSize: 9),
            ),
          )).toList(),
        )),
      ],
    );
  }
  
  static pw.Widget buildInvoiceTemplate({
    required String invoiceNumber,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required String customerName,
    required String customerAddress,
    required List<Map<String, dynamic>> lineItems,
    required double subtotal,
    required double tax,
    required double total,
    String? notes,
    String companyName = 'GUD Express',
    String companyAddress = '123 Main St\nCity, ST 12345\nPhone: (555) 123-4567',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  companyAddress,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  invoiceNumber,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  customerName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                pw.Text(
                  customerAddress,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                buildInfoRow('Invoice Date:', formatDate(invoiceDate)),
                buildInfoRow('Due Date:', formatDate(dueDate)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        buildTable(
          headers: ['Description', 'Qty', 'Rate', 'Amount'],
          rows: lineItems.map((item) => [
            item['description'].toString(),
            item['quantity'].toString(),
            formatCurrency(item['rate'] as double),
            formatCurrency(item['amount'] as double),
          ]).toList(),
          columnWidths: [3, 1, 1.5, 1.5],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  buildInfoRow('Subtotal:', formatCurrency(subtotal)),
                  buildInfoRow('Tax:', formatCurrency(tax)),
                  pw.Divider(),
                  buildInfoRow('Total:', formatCurrency(total)),
                ],
              ),
            ),
          ],
        ),
        if (notes != null && notes.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
        pw.Spacer(),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page $pageNumber of $totalPages',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
      ),
    );
  }
}
