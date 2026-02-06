import 'package:flutter/material.dart';
import '../services/offline_support_service.dart';

/// Offline indicator banner widget
/// 
/// Shows when app is offline with pending sync count
/// - Red banner when offline
/// - Yellow banner when syncing
/// - Auto-hides when online
/// - Tap to show pending operations dialog
class OfflineIndicator extends StatefulWidget {
  final OfflineSupportService offlineService;

  const OfflineIndicator({
    super.key,
    required this.offlineService,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _isSyncing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize with current status
    _isOnline = widget.offlineService.isOnline;
    if (!_isOnline) {
      _animationController.forward();
    }

    // Listen to online status changes
    widget.offlineService.onlineStatus.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          if (!isOnline) {
            _animationController.forward();
          } else {
            // Delay hiding to show success briefly
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _isOnline) {
                _animationController.reverse();
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showPendingOperations() {
    showDialog(
      context: context,
      builder: (context) => _PendingOperationsDialog(
        offlineService: widget.offlineService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: StreamBuilder<bool>(
        stream: widget.offlineService.onlineStatus,
        initialData: _isOnline,
        builder: (context, snapshot) {
          final isOnline = snapshot.data ?? true;
          
          // Don't show anything if online
          if (isOnline && widget.offlineService.pendingOperationsCount == 0) {
            return const SizedBox.shrink();
          }

          final pendingCount = widget.offlineService.pendingOperationsCount;
          final backgroundColor = isOnline
              ? (_isSyncing ? Colors.amber : Colors.green)
              : Colors.red;
          
          final message = isOnline
              ? (_isSyncing
                  ? 'Syncing $pendingCount operations...'
                  : 'Back online - Synced!')
              : 'Offline - $pendingCount pending operations';

          final icon = isOnline
              ? (_isSyncing ? Icons.sync : Icons.check_circle)
              : Icons.cloud_off;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: backgroundColor,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: pendingCount > 0 ? _showPendingOperations : null,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _isSyncing ? 1.0 : 0.0,
                          duration: const Duration(seconds: 1),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (pendingCount > 0)
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _startSyncAnimation() {
    setState(() {
      _isSyncing = true;
    });
    
    // Simulate sync duration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    });
  }
}

/// Dialog showing pending operations
class _PendingOperationsDialog extends StatelessWidget {
  final OfflineSupportService offlineService;

  const _PendingOperationsDialog({
    required this.offlineService,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pending Operations'),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: offlineService.getPendingOperations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final operations = snapshot.data ?? [];

          if (operations.isEmpty) {
            return const Text('No pending operations');
          }

          return SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: operations.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final operation = operations[index];
                return ListTile(
                  leading: Icon(_getOperationIcon(operation['type'])),
                  title: Text(_getOperationTitle(operation['type'])),
                  subtitle: Text(
                    _formatTimestamp(operation['timestamp']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: operation['retries'] > 0
                      ? Chip(
                          label: Text('${operation['retries']} retries'),
                          backgroundColor: Colors.orange[100],
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (offlineService.isOnline)
          TextButton(
            onPressed: () async {
              await offlineService.syncPendingOperations();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Sync Now'),
          ),
      ],
    );
  }

  IconData _getOperationIcon(String type) {
    switch (type) {
      case 'status_update':
        return Icons.update;
      case 'pod_upload':
        return Icons.camera_alt;
      case 'location_update':
        return Icons.location_on;
      case 'create_load':
        return Icons.add_box;
      case 'update_expense':
        return Icons.attach_money;
      default:
        return Icons.sync;
    }
  }

  String _getOperationTitle(String type) {
    switch (type) {
      case 'status_update':
        return 'Status Update';
      case 'pod_upload':
        return 'Proof of Delivery';
      case 'location_update':
        return 'Location Update';
      case 'create_load':
        return 'Create Load';
      case 'update_expense':
        return 'Update Expense';
      default:
        return 'Sync Operation';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
