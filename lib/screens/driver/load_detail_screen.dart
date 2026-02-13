  /// Show accept load confirmation dialog
  Future<void> _showAcceptDialog(LoadModel load, FirestoreService firestoreService) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Load?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Load: ${load.loadNumber}'),
            const SizedBox(height: 8),
            Text('Destination: ${load.deliveryAddress}'),
            const SizedBox(height: 16),
            const Text(
              'Once accepted, you\'ll need to complete this delivery.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await firestoreService.acceptLoad(load.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the load data
          await _refreshLoadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error accepting load: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Show decline load dialog with optional reason
  Future<void> _showDeclineDialog(LoadModel load, FirestoreService firestoreService) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Load?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Load: ${load.loadNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for declining (optional)',
                hintText: 'E.g., Schedule conflict, too far, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline Load'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await firestoreService.declineLoad(
          load.id,
          reason: reasonController.text.isEmpty ? null : reasonController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Load declined'),
              backgroundColor: Colors.orange,
            ),
          );
          // Pop back to home screen since load is declined
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error declining load: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        reasonController.dispose();
      }
    } else {
      reasonController.dispose();
    }
  }

  /// Check if trip buttons should be shown for the given status
  bool _canShowTripButtons(String status) {
    return status == 'accepted' || 
           status == 'assigned' || 
           status == 'picked_up' || 
           status == 'in_transit';
  }