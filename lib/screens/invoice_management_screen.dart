import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import 'invoice_detail_screen.dart';
import 'create_invoice_screen.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final _invoiceService = InvoiceService();
  final _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  InvoiceStatus? _selectedStatus;
  Map<String, double> _totals = {};

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTotals() async {
    try {
      final totals = await _invoiceService.calculateTotalsByStatus();
      if (mounted) {
        setState(() {
          _totals = totals;
        });
      }
    } catch (e) {
      debugPrint('Error loading totals: $e');
    }
  }

  Future<void> _searchInvoices() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await _invoiceService.searchInvoices(query);
      
      if (mounted && results.isNotEmpty) {
        // Show search results in a dialog or navigate to first result
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvoiceDetailScreen(invoice: results.first),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No invoices found')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTotals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateInvoiceScreen(),
            ),
          );
          _loadTotals();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by invoice number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onSubmitted: (_) => _searchInvoices(),
            ),
          ),

          // Totals cards
          if (_totals.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildTotalCard(
                    'Draft',
                    _totals['draft'] ?? 0.0,
                    Colors.grey,
                    Icons.drafts,
                  ),
                  _buildTotalCard(
                    'Sent',
                    _totals['sent'] ?? 0.0,
                    Colors.blue,
                    Icons.send,
                  ),
                  _buildTotalCard(
                    'Paid',
                    _totals['paid'] ?? 0.0,
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildTotalCard(
                    'Total',
                    _totals['total'] ?? 0.0,
                    Colors.purple,
                    Icons.attach_money,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Draft'),
                    selected: _selectedStatus == InvoiceStatus.draft,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? InvoiceStatus.draft : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Sent'),
                    selected: _selectedStatus == InvoiceStatus.sent,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? InvoiceStatus.sent : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Paid'),
                    selected: _selectedStatus == InvoiceStatus.paid,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? InvoiceStatus.paid : null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(),

          // Invoices list
          Expanded(
            child: StreamBuilder<List<Invoice>>(
              stream: _selectedStatus != null
                  ? _invoiceService.streamInvoicesByStatus(_selectedStatus!)
                  : _invoiceService.streamInvoices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: invoices.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return _buildInvoiceCard(invoice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final statusColor = _getStatusColor(invoice.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.receipt, color: statusColor),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invoice.clientInfo.name),
            Text('Issue Date: ${_dateFormat.format(invoice.issueDate)}'),
            Text('Due Date: ${_dateFormat.format(invoice.dueDate)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${invoice.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invoice.status.name.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
          _loadTotals();
        },
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
}
