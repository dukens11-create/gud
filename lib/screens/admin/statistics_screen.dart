import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/statistics_service.dart';
import '../../models/statistics.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _statisticsService = StatisticsService();
  String _selectedPeriod = 'month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  DateTime get _startDate {
    if (_selectedPeriod == 'custom' && _customStartDate != null) {
      return _customStartDate!;
    }
    
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'quarter':
        return DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _endDate {
    if (_selectedPeriod == 'custom' && _customEndDate != null) {
      return _customEndDate!;
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('Week', 'week'),
                  _buildPeriodChip('Month', 'month'),
                  _buildPeriodChip('Quarter', 'quarter'),
                  _buildPeriodChip('Year', 'year'),
                  _buildPeriodChip('Custom', 'custom'),
                ],
              ),
            ),
          ),
          
          // Date range display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

          // Statistics
          Expanded(
            child: FutureBuilder<Statistics>(
              future: _statisticsService.calculateStatistics(
                startDate: _startDate,
                endDate: _endDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final stats = snapshot.data;
                if (stats == null) {
                  return const Center(child: Text('No data available'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Key metrics cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Total Revenue',
                              '\$${stats.totalRevenue.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildMetricCard(
                              'Total Expenses',
                              '\$${stats.totalExpenses.toStringAsFixed(2)}',
                              Icons.money_off,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Net profit card
                      _buildLargeMetricCard(
                        'Net Profit',
                        '\$${stats.netProfit.toStringAsFixed(2)}',
                        Icons.trending_up,
                        stats.netProfit >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      
                      // Load metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Total Loads',
                              '${stats.totalLoads}',
                              Icons.local_shipping,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildMetricCard(
                              'Delivered',
                              '${stats.deliveredLoads}',
                              Icons.done_all,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Rate metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Avg Rate',
                              '\$${stats.averageRate.toStringAsFixed(2)}',
                              Icons.calculate,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildMetricCard(
                              'Rate/Mile',
                              '\$${stats.ratePerMile.toStringAsFixed(2)}',
                              Icons.timeline,
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Miles card
                      _buildMetricCard(
                        'Total Miles',
                        '${stats.totalMiles.toStringAsFixed(1)} mi',
                        Icons.route,
                        Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      
                      // Driver performance
                      if (stats.driverStats.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Driver Performance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...stats.driverStats.entries.map((entry) {
                                  final driverData = entry.value as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driverData['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Revenue: \$${(driverData['revenue'] ?? 0).toStringAsFixed(2)}'),
                                            Text('Loads: ${driverData['loads']} (${driverData['delivered']} delivered)'),
                                          ],
                                        ),
                                        const Divider(),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) async {
          if (value == 'custom') {
            // Show date range picker
            final DateTimeRange? range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDateRange: DateTimeRange(
                start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                end: _customEndDate ?? DateTime.now(),
              ),
            );
            
            if (range != null) {
              setState(() {
                _selectedPeriod = value;
                _customStartDate = range.start;
                _customEndDate = range.end;
              });
            }
          } else {
            setState(() {
              _selectedPeriod = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(icon, color: color, size: 48),
          ],
        ),
      ),
    );
  }
}
