import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import 'invoice_detail_screen.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final _invoiceService = InvoiceService();
  final _searchController = TextEditingController();
  
  String _selectedStatus = 'all';
  String _searchQuery = '';
  
  final _dateFormat = DateFormat('MMM dd, yyyy');
  final _currencyFormat = NumberFormat.currency(symbol: '\$');
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Stream<List<Invoice>> _getInvoicesStream() {
    if (_selectedStatus == 'all') {
      return _invoiceService.getAllInvoices();
    } else {
      return _invoiceService.getInvoicesByStatus(_selectedStatus);
    }
  }
  
  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    if (_searchQuery.isEmpty) return invoices;
    
    final query = _searchQuery.toLowerCase();
    return invoices.where((invoice) {
      return invoice.invoiceNumber.toLowerCase().contains(query) ||
             invoice.customerName.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _createNewInvoice() async {
    // Navigate to invoice creation screen
    // For now, show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create invoice from Load History or manually')),
    );
  }
  
  void _navigateToInvoiceDetail(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailScreen(invoice: invoice),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewInvoice,
            tooltip: 'Create Invoice',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by invoice # or customer...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'draft', label: Text('Draft')),
                      ButtonSegment(value: 'sent', label: Text('Sent')),
                      ButtonSegment(value: 'paid', label: Text('Paid')),
                      ButtonSegment(value: 'overdue', label: Text('Overdue')),
                    ],
                    selected: {_selectedStatus},
                    onSelectionChanged: (Set<String> selected) {
                      setState(() => _selectedStatus = selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Invoice>>(
              stream: _getInvoicesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final invoices = _filterInvoices(snapshot.data!);
                
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No invoices found'),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _createNewInvoice,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Invoice'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return _buildInvoiceCard(invoice);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewInvoice,
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }
  
  Widget _buildInvoiceCard(Invoice invoice) {
    final isOverdue = invoice.isOverdue;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToInvoiceDetail(invoice),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.customerName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(invoice.status, isOverdue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _dateFormat.format(invoice.invoiceDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _dateFormat.format(invoice.dueDate),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isOverdue ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _currencyFormat.format(invoice.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!invoice.isPaid) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: invoice.total > 0 ? invoice.amountPaid / invoice.total : 0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverdue ? Colors.red : Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: ${_currencyFormat.format(invoice.balance)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status, bool isOverdue) {
    Color color;
    String label;
    
    if (isOverdue) {
      color = Colors.red;
      label = 'Overdue';
    } else {
      switch (status) {
        case 'paid':
          color = Colors.green;
          label = 'Paid';
          break;
        case 'sent':
          color = Colors.blue;
          label = 'Sent';
          break;
        case 'draft':
          color = Colors.grey;
          label = 'Draft';
          break;
        default:
          color = Colors.orange;
          label = status;
      }
    }
    
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontSize: 12),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
