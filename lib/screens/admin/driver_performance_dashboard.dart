import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/driver_extended_service.dart';

/// Driver Performance Dashboard Screen
/// 
/// Displays comprehensive performance metrics for all drivers:
/// - Ratings and reviews
/// - Completed loads and earnings
/// - On-time delivery rates
/// - Status overview
class DriverPerformanceDashboard extends StatefulWidget {
  const DriverPerformanceDashboard({super.key});

  @override
  State<DriverPerformanceDashboard> createState() =>
      _DriverPerformanceDashboardState();
}

class _DriverPerformanceDashboardState
    extends State<DriverPerformanceDashboard> {
  final _service = DriverExtendedService();
  List<Map<String, dynamic>> _drivers = [];
  bool _loading = true;
  String _sortBy = 'name'; // name, rating, loads, earnings, onTime
  String? _errorMessage;
  String? _indexCreationUrl;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _indexCreationUrl = null;
    });

    try {
      final drivers = await _service.getAllDriversPerformance();
      setState(() {
        _drivers = drivers;
        _sortDrivers();
        _loading = false;
      });
    } on FirebaseException catch (e) {
      // Handle Firestore-specific errors, especially missing indexes
      setState(() => _loading = false);
      
      final errorMsg = e.message ?? e.toString();
      final isIndexError = e.code == 'failed-precondition' || 
                          errorMsg.contains('index') ||
                          errorMsg.contains('requires an index');
      
      if (isIndexError) {
        // Extract index creation URL from error message if available
        // Firebase error messages often contain URLs wrapped in quotes or parentheses
        // The regex captures the URL but stops at common terminators
        final urlPattern = RegExp(
          r'https://console\.firebase\.google\.com/[^\s\)\]' r'"' r"'\,]+",
          caseSensitive: true,
        );
        final urlMatch = urlPattern.firstMatch(errorMsg);
        
        setState(() {
          _errorMessage = 'A Firestore composite index is required to display driver performance data.';
          _indexCreationUrl = urlMatch?.group(0);
        });
      } else {
        setState(() {
          _errorMessage = 'Error loading driver data: ${e.message ?? e.code}';
        });
      }
    } catch (e) {
      // Handle other errors
      setState(() {
        _loading = false;
        _errorMessage = 'Error loading data: $e';
      });
    }
  }

  void _sortDrivers() {
    switch (_sortBy) {
      case 'name':
        _drivers.sort((a, b) =>
            (a['driverName'] as String).compareTo(b['driverName'] as String));
        break;
      case 'rating':
        _drivers.sort((a, b) =>
            (b['averageRating'] as double).compareTo(a['averageRating'] as double));
        break;
      case 'loads':
        _drivers.sort((a, b) =>
            (b['completedLoads'] as int).compareTo(a['completedLoads'] as int));
        break;
      case 'earnings':
        _drivers.sort((a, b) =>
            (b['totalEarnings'] as double).compareTo(a['totalEarnings'] as double));
        break;
      case 'onTime':
        _drivers.sort((a, b) => (b['onTimeDeliveryRate'] as int)
            .compareTo(a['onTimeDeliveryRate'] as int));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortDrivers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Name')),
              const PopupMenuItem(value: 'rating', child: Text('Rating')),
              const PopupMenuItem(value: 'loads', child: Text('Loads')),
              const PopupMenuItem(value: 'earnings', child: Text('Earnings')),
              const PopupMenuItem(value: 'onTime', child: Text('On-Time Rate')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _drivers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPerformanceData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drivers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildSummaryCards();
                          }
                          return _buildDriverCard(_drivers[index - 1]);
                        },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No drivers found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add drivers to see their performance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isIndexError = _indexCreationUrl != null || 
                        (_errorMessage?.contains('index') ?? false);
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIndexError ? Icons.error_outline : Icons.error,
              size: 80,
              color: isIndexError ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isIndexError 
                  ? 'Firestore Index Required'
                  : 'Error Loading Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isIndexError) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                            color: Colors.orange.shade700, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'What\'s needed?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The driver dashboard query requires a composite index on the following fields:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Collection: loads',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• driverId (Ascending)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                          Text(
                            '• status (Ascending)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_indexCreationUrl != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Display the URL in a dialog for the admin to copy and open
                          // We avoid using url_launcher to keep dependencies minimal
                          // and let admins use their preferred browser/context
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Create Index'),
                              content: SelectableText(
                                'Click the link below to create the required index:\n\n$_indexCreationUrl',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('CLOSE'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('View Index Creation Link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(
                        'To create this index:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Go to Firebase Console\n'
                        '2. Navigate to Firestore → Indexes\n'
                        '3. Create a composite index with the fields above\n'
                        '4. Or deploy via CLI: firebase deploy --only firestore:indexes',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadPerformanceData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalDrivers = _drivers.length;
    final totalLoads = _drivers.fold<int>(
      0,
      (sum, d) => sum + (d['totalLoads'] as int? ?? 0),
    );
    final completedLoads = _drivers.fold<int>(
      0,
      (sum, d) => sum + (d['completedLoads'] as int? ?? 0),
    );
    final totalEarnings = _drivers.fold<double>(
      0.0,
      (sum, d) => sum + (d['totalEarnings'] as double? ?? 0.0),
    );
    final avgRating = totalDrivers > 0
        ? _drivers.fold<double>(
              0.0,
              (sum, d) => sum + (d['averageRating'] as double),
            ) /
            totalDrivers
        : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.people,
                title: 'Drivers',
                value: totalDrivers.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.local_shipping,
                title: 'Total Loads',
                value: totalLoads.toString(),
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.attach_money,
                title: 'Total Earnings',
                value: '\$${totalEarnings.toStringAsFixed(0)}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.star,
                title: 'Avg Rating',
                value: avgRating.toStringAsFixed(1),
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Driver Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDriverCard(Map<String, dynamic> driver) {
    final rating = (driver['averageRating'] as double? ?? 0.0);
    final totalRatings = (driver['totalRatings'] as int? ?? 0);
    final loads = (driver['completedLoads'] as int? ?? 0);
    final earnings = (driver['totalEarnings'] as double? ?? 0.0);
    final onTimeRate = (driver['onTimeDeliveryRate'] as int? ?? 0);
    final status = (driver['status'] as String? ?? 'unknown');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDriverDetails(driver),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      (driver['driverName'] as String).isNotEmpty
                          ? (driver['driverName'] as String)
                              .substring(0, 1)
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['driverName'] as String,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Truck: ${driver['truckNumber']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const Divider(height: 24),

              // Performance metrics
              Row(
                children: [
                  Expanded(
                    child: _MetricItem(
                      icon: Icons.star,
                      label: 'Rating',
                      value: rating.toStringAsFixed(1),
                      subtitle: '$totalRatings reviews',
                      color: Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _MetricItem(
                      icon: Icons.local_shipping,
                      label: 'Loads',
                      value: loads.toString(),
                      subtitle: 'completed',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricItem(
                      icon: Icons.attach_money,
                      label: 'Earnings',
                      value: '\$${earnings.toStringAsFixed(0)}',
                      subtitle: 'total',
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _MetricItem(
                      icon: Icons.schedule,
                      label: 'On-Time',
                      value: '$onTimeRate%',
                      subtitle: 'delivery rate',
                      color: onTimeRate >= 90
                          ? Colors.green
                          : onTimeRate >= 70
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(driver['driverName'] as String),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Driver ID', driver['driverId'] as String),
              _DetailRow('Truck Number', driver['truckNumber'] as String),
              _DetailRow('Status', driver['status'] as String? ?? 'unknown'),
              const Divider(height: 24),
              _DetailRow('Average Rating',
                  (driver['averageRating'] as double? ?? 0.0).toStringAsFixed(2)),
              _DetailRow(
                  'Total Ratings', (driver['totalRatings'] as int? ?? 0).toString()),
              _DetailRow('Total Loads',
                  (driver['totalLoads'] as int? ?? 0).toString()),
              _DetailRow('Completed Loads',
                  (driver['completedLoads'] as int? ?? 0).toString()),
              _DetailRow('Total Earnings',
                  '\$${(driver['totalEarnings'] as double? ?? 0.0).toStringAsFixed(2)}'),
              _DetailRow('On-Time Delivery',
                  '${driver['onTimeDeliveryRate'] as int? ?? 0}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        label = 'Available';
        break;
      case 'on_trip':
      case 'on_duty':
        color = Colors.blue;
        label = 'On Duty';
        break;
      case 'off_duty':
        color = Colors.orange;
        label = 'Off Duty';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Inactive';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
