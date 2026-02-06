import 'package:flutter/material.dart';
import 'dart:async';
import '../services/offline_service.dart';
import '../services/sync_service.dart';

/// Offline Indicator Widget
/// 
/// Displays connection status with:
/// - Offline banner when disconnected
/// - Animated connectivity icon
/// - Tap to retry connection
/// - Pending operations count
/// - Sync progress indicator
/// - Material Design styling
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  final OfflineService _offlineService = OfflineService();
  final SyncService _syncService = SyncService();
  
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<SyncProgress>? _syncSubscription;
  
  bool _isOnline = true;
  int _pendingCount = 0;
  SyncProgress? _syncProgress;
  
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    // Get initial state
    _isOnline = _offlineService.isOnline;
    _pendingCount = await _offlineService.getPendingOperationsCount();
    
    if (mounted) {
      setState(() {});
    }

    // Listen for connectivity changes
    _connectivitySubscription = _offlineService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
      _updatePendingCount();
    });

    // Listen for sync progress
    _syncSubscription = _syncService.syncProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _syncProgress = progress;
        });
      }
      _updatePendingCount();
    });
  }

  Future<void> _updatePendingCount() async {
    final count = await _offlineService.getPendingOperationsCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!_isOnline) {
      // Try to trigger a sync check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking connection...'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (_pendingCount > 0 && !_syncService.isSyncing) {
      // Trigger manual sync
      await _syncService.forceSyncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if online and no pending operations
    if (_isOnline && _pendingCount == 0 && _syncProgress?.status != SyncStatus.syncing) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _shouldShow() ? Offset.zero : const Offset(0, -1),
      child: Material(
        color: _getBackgroundColor(),
        elevation: 4,
        child: SafeArea(
          bottom: false,
          child: InkWell(
            onTap: _handleTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Animated icon
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Icon(
                      _getIcon(),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Status text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMainText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_getSubText() != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _getSubText()!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Progress indicator or action
                  if (_syncProgress?.status == SyncStatus.syncing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: _syncProgress!.progress,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (_pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.refresh,
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
  }

  bool _shouldShow() {
    return !_isOnline || 
           _pendingCount > 0 || 
           _syncProgress?.status == SyncStatus.syncing;
  }

  Color _getBackgroundColor() {
    if (_syncProgress?.status == SyncStatus.syncing) {
      return Colors.blue;
    } else if (!_isOnline) {
      return Colors.orange.shade700;
    } else if (_pendingCount > 0) {
      return Colors.amber.shade700;
    }
    return Colors.grey;
  }

  IconData _getIcon() {
    if (_syncProgress?.status == SyncStatus.syncing) {
      return Icons.sync;
    } else if (!_isOnline) {
      return Icons.cloud_off;
    } else if (_pendingCount > 0) {
      return Icons.cloud_upload;
    }
    return Icons.cloud_done;
  }

  String _getMainText() {
    if (_syncProgress?.status == SyncStatus.syncing) {
      return 'Syncing...';
    } else if (!_isOnline) {
      return 'You\'re offline';
    } else if (_pendingCount > 0) {
      return 'Ready to sync';
    }
    return 'Connected';
  }

  String? _getSubText() {
    if (_syncProgress?.status == SyncStatus.syncing) {
      return '${_syncProgress!.completed} of ${_syncProgress!.total} operations';
    } else if (!_isOnline && _pendingCount > 0) {
      return '$_pendingCount operation${_pendingCount == 1 ? '' : 's'} pending';
    } else if (_pendingCount > 0) {
      return 'Tap to sync $_pendingCount operation${_pendingCount == 1 ? '' : 's'}';
    }
    return null;
  }
}

/// Simple offline banner widget (lighter version)
class OfflineBanner extends StatelessWidget {
  final OfflineService _offlineService = OfflineService();

  OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _offlineService.connectivityStream,
      initialData: _offlineService.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.shade700,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'No internet connection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Connectivity status widget (for use in settings or debug)
class ConnectivityStatus extends StatefulWidget {
  const ConnectivityStatus({super.key});

  @override
  State<ConnectivityStatus> createState() => _ConnectivityStatusState();
}

class _ConnectivityStatusState extends State<ConnectivityStatus> {
  final OfflineService _offlineService = OfflineService();
  final SyncService _syncService = SyncService();

  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _syncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sync Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow(
              'Connection',
              _status['is_online'] == true ? 'Online' : 'Offline',
              _status['is_online'] == true ? Colors.green : Colors.red,
            ),
            
            _buildStatusRow(
              'Syncing',
              _status['is_syncing'] == true ? 'Yes' : 'No',
              _status['is_syncing'] == true ? Colors.blue : Colors.grey,
            ),
            
            _buildStatusRow(
              'Pending Operations',
              '${_status['pending_operations'] ?? 0}',
              Colors.orange,
            ),
            
            _buildStatusRow(
              'Unresolved Conflicts',
              '${_status['unresolved_conflicts'] ?? 0}',
              Colors.red,
            ),
            
            const SizedBox(height: 16),
            
            // Manual sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _status['is_online'] == true && _status['is_syncing'] != true
                    ? () async {
                        await _syncService.forceSyncNow();
                        await _loadStatus();
                      }
                    : null,
                icon: const Icon(Icons.sync),
                label: const Text('Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
