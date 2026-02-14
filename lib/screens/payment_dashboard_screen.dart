import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import '../models/payment.dart';

/// Payment Dashboard Screen
///
/// Displays payment records for both drivers and admins:
/// - **Drivers**: See only their own payments
/// - **Admins**: See all payments with filtering options
///
/// Features:
/// - Summary cards showing totals
/// - Status and date range filtering
/// - Search functionality
/// - Admin can mark payments as paid
/// - Pull-to-refresh
class PaymentDashboardScreen extends StatefulWidget {
  const PaymentDashboardScreen({super.key});

  @override
  State<PaymentDashboardScreen> createState() => _PaymentDashboardScreenState();
}

class _PaymentDashboardScreenState extends State<PaymentDashboardScreen> {
  final _paymentService = PaymentService();
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, pending, paid
  DateTimeRange? _dateRange;
  String? _selectedDriverId;
  bool _isAdmin = false;
  bool _loading = true;
  String? _errorMessage;
  String? _currentUserId;
  Map<String, String> _driverNames = {}; // Cache driver names
  List<String> _selectedPayments = []; // For bulk actions

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Please log in to view payments';
          _loading = false;
        });
        return;
      }

      _currentUserId = user.uid;

      // Check user role
      final role = await _firestoreService.getUserRole(user.uid);
      setState(() {
        _isAdmin = role == 'admin';
        _loading = false;
      });

      // Load driver names if admin
      if (_isAdmin) {
        _loadDriverNames();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing screen: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadDriverNames() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final names = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        names[doc.id] = data['name'] ?? 'Unknown Driver';
      }
      setState(() {
        _driverNames = names;
      });
    } catch (e) {
      print('Error loading driver names: $e');
    }
  }

  Stream<List<Payment>> _getPaymentsStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    if (_isAdmin) {
      // Admin sees all payments or filtered by driver
      if (_selectedDriverId == null) {
        // Stream all payments for admin
        return FirebaseFirestore.instance
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) =>
                snapshot.docs.map((doc) => Payment.fromDoc(doc)).toList());
      } else {
        // Stream payments for selected driver
        return _paymentService.streamDriverPayments(_selectedDriverId!);
      }
    } else {
      // Driver sees only their own payments
      return _paymentService.streamDriverPayments(_currentUserId!);
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      // Status filter
      if (_statusFilter != 'all' && payment.status != _statusFilter) {
        return false;
      }

      // Date range filter
      if (_dateRange != null) {
        final paymentDate = payment.paymentDate ?? payment.createdAt;
        if (paymentDate.isBefore(_dateRange!.start) ||
            paymentDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final driverName = _driverNames[payment.driverId]?.toLowerCase() ?? '';
        return payment.loadId.toLowerCase().contains(query) ||
            payment.id.toLowerCase().contains(query) ||
            driverName.contains(query);
      }

      return true;
    }).toList();
  }

  Future<void> _markAsPaid(String paymentId) async {
    try {
      await _paymentService.markAsPaid(paymentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markMultipleAsPaid() async {
    if (_selectedPayments.isEmpty) return;

    final count = _selectedPayments.length;
    try {
      for (final paymentId in _selectedPayments) {
        await _paymentService.markAsPaid(paymentId);
      }
      setState(() {
        _selectedPayments.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$count payments marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeScreen,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Payment Dashboard (Admin)' : 'My Payments'),
        actions: [
          if (_isAdmin && _selectedPayments.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text(_selectedPayments.length.toString()),
                child: const Icon(Icons.check_circle),
              ),
              onPressed: _markMultipleAsPaid,
              tooltip: 'Mark selected as paid',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<List<Payment>>(
        stream: _getPaymentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error);
          }

          final allPayments = snapshot.data ?? [];
          final filteredPayments = _filterPayments(allPayments);

          if (allPayments.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: Column(
              children: [
                _buildSummaryCards(allPayments),
                _buildFilterSection(),
                Expanded(
                  child: filteredPayments.isEmpty
                      ? _buildNoResultsState()
                      : _buildPaymentsList(filteredPayments),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<Payment> payments) {
    final pendingPayments =
        payments.where((p) => p.status == 'pending').toList();
    final paidPayments = payments.where((p) => p.status == 'paid').toList();

    final totalPending =
        pendingPayments.fold(0.0, (sum, p) => sum + p.amount);
    final totalPaid = paidPayments.fold(0.0, (sum, p) => sum + p.amount);
    final avgPayment = payments.isEmpty
        ? 0.0
        : payments.fold(0.0, (sum, p) => sum + p.amount) / payments.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '💰 Pending',
                  '\$${totalPending.toStringAsFixed(2)}',
                  '${pendingPayments.length} payments',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  '✅ Paid',
                  '\$${totalPaid.toStringAsFixed(2)}',
                  '${paidPayments.length} payments',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '📊 Count',
                  '${payments.length}',
                  'total payments',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  '💵 Average',
                  '\$${avgPayment.toStringAsFixed(2)}',
                  'per payment',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, String subtitle, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by load number or payment ID...',
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) => setState(() => _statusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) => setState(() => _statusFilter = 'pending'),
                  avatar: const Icon(Icons.schedule, size: 18),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Paid'),
                  selected: _statusFilter == 'paid',
                  onSelected: (_) => setState(() => _statusFilter = 'paid'),
                  avatar: const Icon(Icons.check_circle, size: 18),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: Text(
                    _dateRange == null
                        ? 'Date Range'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  ),
                  avatar: const Icon(Icons.date_range, size: 18),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dateRange = null),
                    tooltip: 'Clear date filter',
                  ),
                ],
                if (_isAdmin) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text(
                      _selectedDriverId == null
                          ? 'All Drivers'
                          : _driverNames[_selectedDriverId] ?? 'Driver',
                    ),
                    avatar: const Icon(Icons.person, size: 18),
                    onPressed: () => _showDriverFilter(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showDriverFilter() async {
    final drivers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'driver')
        .get();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Driver'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Drivers'),
                selected: _selectedDriverId == null,
                onTap: () {
                  setState(() => _selectedDriverId = null);
                  Navigator.pop(context);
                },
              ),
              ...drivers.docs.map((doc) {
                final data = doc.data();
                return ListTile(
                  title: Text(data['name'] ?? 'Unknown'),
                  subtitle: Text(doc.id),
                  selected: _selectedDriverId == doc.id,
                  onTap: () {
                    setState(() => _selectedDriverId = doc.id);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final driverName = _driverNames[payment.driverId] ?? 'Unknown Driver';
    final isSelected = _selectedPayments.contains(payment.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (_isAdmin) {
            setState(() {
              if (isSelected) {
                _selectedPayments.remove(payment.id);
              } else {
                _selectedPayments.add(payment.id);
              }
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount (large, prominent)
                  Text(
                    '\$${payment.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: payment.status == 'paid'
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          payment.status == 'paid'
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          payment.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Load Number
              Row(
                children: [
                  const Icon(Icons.local_shipping, size: 16,
                      color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Load: ${payment.loadId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 8),
                // Driver Name (admin only)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Driver: $driverName',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // Load Rate and Commission
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Load Rate: \$${payment.loadRate.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.percent, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Commission: ${payment.commissionRatePercent}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Created Date
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16,
                      color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(payment.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (payment.paymentDate != null) ...[
                const SizedBox(height: 8),
                // Payment Date
                Row(
                  children: [
                    const Icon(Icons.event_available, size: 16,
                        color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Paid: ${DateFormat('MMM dd, yyyy').format(payment.paymentDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // Admin actions
              if (_isAdmin && payment.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_box, color: Colors.blue),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _markAsPaid(payment.id),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Mark as Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Payments Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdmin
                ? 'Payments will appear here when loads are delivered'
                : 'Your payments will appear here when loads are completed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object? error) {
    final errorStr = error.toString();
    final isIndexError = errorStr.contains('index') ||
        errorStr.contains('requires an index') ||
        (error is FirebaseException && error.code == 'failed-precondition');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIndexError ? Icons.info_outline : Icons.error_outline,
              size: 64,
              color: isIndexError ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isIndexError
                  ? 'Firestore Index Required'
                  : 'Error Loading Payments',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isIndexError) ...[
              const Text(
                'The payment dashboard requires Firestore composite indexes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please deploy indexes using:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'firebase deploy --only firestore:indexes',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ] else ...[
              Text(
                errorStr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
