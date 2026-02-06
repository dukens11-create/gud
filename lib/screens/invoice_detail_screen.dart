import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/pdf_generator_service.dart';
import 'create_invoice_screen.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final invoiceService = InvoiceService();
    final pdfService = PDFGeneratorService();

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          // Edit button (only for draft)
          if (invoice.status == InvoiceStatus.draft)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateInvoiceScreen(invoice: invoice),
                  ),
                );
              },
              tooltip: 'Edit Invoice',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _getStatusColor(invoice.status).withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(invoice.status),
                    color: _getStatusColor(invoice.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ${invoice.status.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(invoice.status),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice dates
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Invoice Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Invoice Number', invoice.invoiceNumber),
                          _buildInfoRow('Issue Date', dateFormat.format(invoice.issueDate)),
                          _buildInfoRow('Due Date', dateFormat.format(invoice.dueDate)),
                          if (invoice.loadId != null)
                            _buildInfoRow('Load ID', invoice.loadId!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            invoice.companyInfo.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(invoice.companyInfo.address),
                          Text('${invoice.companyInfo.city}, ${invoice.companyInfo.state} ${invoice.companyInfo.zip}'),
                          if (invoice.companyInfo.phone != null)
                            Text('Phone: ${invoice.companyInfo.phone}'),
                          if (invoice.companyInfo.email != null)
                            Text('Email: ${invoice.companyInfo.email}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Client info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill To',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Text(
                            invoice.clientInfo.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(invoice.clientInfo.address),
                          Text('${invoice.clientInfo.city}, ${invoice.clientInfo.state} ${invoice.clientInfo.zip}'),
                          if (invoice.clientInfo.phone != null)
                            Text('Phone: ${invoice.clientInfo.phone}'),
                          if (invoice.clientInfo.email != null)
                            Text('Email: ${invoice.clientInfo.email}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Line items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Line Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1.5),
                              3: FlexColumnWidth(1.5),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                ),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Description',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Qty',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Unit Price',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      'Amount',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              ...invoice.lineItems.map((item) => TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(item.description),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(item.quantity.toStringAsFixed(0)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text('\$${item.unitPrice.toStringAsFixed(2)}'),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          '\$${item.amount.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Totals
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTotalRow('Subtotal', invoice.subtotal),
                          _buildTotalRow('Tax', invoice.tax),
                          const Divider(thickness: 2),
                          _buildTotalRow(
                            'TOTAL',
                            invoice.total,
                            isBold: true,
                            fontSize: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Notes
                  if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            Text(invoice.notes!),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Generate PDF
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final file = await pdfService.generateInvoicePDF(invoice);
                            
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('PDF generated: ${file.path}'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Generate PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Share invoice
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            final file = await pdfService.generateInvoicePDF(invoice);
                            
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: 'Invoice ${invoice.invoiceNumber}',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share Invoice'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status action buttons
                      if (invoice.status == InvoiceStatus.draft) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await invoiceService.markAsSent(invoice.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invoice marked as sent'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Mark as Sent'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                      if (invoice.status == InvoiceStatus.sent) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await invoiceService.markAsPaid(invoice.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invoice marked as paid'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Paid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount,
      {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.drafts;
      case InvoiceStatus.sent:
        return Icons.send;
      case InvoiceStatus.paid:
        return Icons.check_circle;
    }
  }
}
