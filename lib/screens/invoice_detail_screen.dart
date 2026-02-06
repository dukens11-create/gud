import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/export_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _invoiceService = InvoiceService();
  final _pdfService = PdfGeneratorService();
  final _exportService = ExportService();
  
  late Invoice _invoice;
  bool _isGenerating = false;
  
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  
  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }
  
  Future<void> _markAsPaid() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _PaymentDialog(
        remainingBalance: _invoice.balance,
      ),
    );
    
    if (amount == null || amount <= 0) return;
    
    try {
      await _invoiceService.markAsPaid(
        invoiceId: _invoice.id,
        amount: amount,
        method: 'Manual Entry',
      );
      
      final updatedInvoice = await _invoiceService.getInvoice(_invoice.id);
      if (updatedInvoice != null) {
        setState(() => _invoice = updatedInvoice);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    }
  }
  
  Future<void> _generatePDF() async {
    setState(() => _isGenerating = true);
    
    try {
      final file = await _pdfService.generateInvoicePDF(_invoice);
      await _exportService.shareFile(file);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }
  
  Future<void> _updateStatus(String newStatus) async {
    try {
      await _invoiceService.updateInvoice(_invoice.id, {'status': newStatus});
      
      final updatedInvoice = await _invoiceService.getInvoice(_invoice.id);
      if (updatedInvoice != null) {
        setState(() => _invoice = updatedInvoice);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit functionality coming soon')),
              );
            },
            tooltip: 'Edit Invoice',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'draft':
                case 'sent':
                  _updateStatus(value);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'draft',
                child: Text('Mark as Draft'),
              ),
              const PopupMenuItem(
                value: 'sent',
                child: Text('Mark as Sent'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            const SizedBox(height: 24),
            _buildInvoiceInfo(),
            const SizedBox(height: 24),
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            _buildLineItems(),
            const SizedBox(height: 24),
            _buildTotals(),
            if (_invoice.notes != null && _invoice.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotes(),
            ],
            if (_invoice.payments.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildPaymentHistory(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildStatusBanner() {
    final isOverdue = _invoice.isOverdue;
    final isPaid = _invoice.isPaid;
    
    Color color;
    IconData icon;
    String message;
    
    if (isPaid) {
      color = Colors.green;
      icon = Icons.check_circle;
      message = 'This invoice has been paid in full';
    } else if (isOverdue) {
      color = Colors.red;
      icon = Icons.warning;
      message = 'This invoice is overdue';
    } else {
      color = Colors.orange;
      icon = Icons.info;
      message = 'Payment pending';
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInvoiceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Invoice Number', _invoice.invoiceNumber),
            _buildInfoRow('Invoice Date', _dateFormat.format(_invoice.invoiceDate)),
            _buildInfoRow('Due Date', _dateFormat.format(_invoice.dueDate)),
            _buildInfoRow('Status', _invoice.status.toUpperCase()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Customer', _invoice.customerName),
            _buildInfoRow('Address', _invoice.customerAddress),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineItems() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Line Items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
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
                    color: Colors.grey[200],
                  ),
                  children: [
                    _buildTableHeader('Description'),
                    _buildTableHeader('Qty'),
                    _buildTableHeader('Rate'),
                    _buildTableHeader('Amount'),
                  ],
                ),
                ..._invoice.lineItems.map((item) => TableRow(
                  children: [
                    _buildTableCell(item.description),
                    _buildTableCell(item.quantity.toString()),
                    _buildTableCell(_currencyFormat.format(item.rate)),
                    _buildTableCell(_currencyFormat.format(item.amount)),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTotals() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', _invoice.subtotal),
            _buildTotalRow('Tax', _invoice.tax),
            const Divider(),
            _buildTotalRow('Total', _invoice.total, isBold: true),
            if (_invoice.amountPaid > 0) ...[
              _buildTotalRow('Amount Paid', _invoice.amountPaid, color: Colors.green),
              const Divider(),
              _buildTotalRow('Balance Due', _invoice.balance, isBold: true, color: Colors.red),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_invoice.notes!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._invoice.payments.map((payment) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dateFormat.format(payment.date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        payment.method,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    _currencyFormat.format(payment.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )),
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
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
  
  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
  
  Widget _buildTotalRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_invoice.isPaid)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _markAsPaid,
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
              ),
            ),
          if (!_invoice.isPaid) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePDF,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: const Text('Generate PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final double remainingBalance;

  const _PaymentDialog({required this.remainingBalance});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _amountController.text = widget.remainingBalance.toStringAsFixed(2);
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Payment Amount',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            if (amount > widget.remainingBalance) {
              return 'Amount exceeds balance';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              Navigator.pop(context, amount);
            }
          },
          child: const Text('Record'),
        ),
      ],
    );
  }
}
