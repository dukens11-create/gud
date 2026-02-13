import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/driver_extended.dart';
import '../../services/driver_extended_service.dart';

/// Screen for admins to review and verify driver documents
/// 
/// Features:
/// - View pending documents
/// - Approve or reject documents
/// - Add verification notes
/// - View document details
class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  final _service = DriverExtendedService();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        elevation: 2,
      ),
      body: StreamBuilder<List<DriverDocument>>(
        stream: _service.streamPendingDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final documents = snapshot.data ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending documents',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All documents have been reviewed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return _DocumentCard(
                document: document,
                onVerify: () => _verifyDocument(document, true),
                onReject: () => _verifyDocument(document, false),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _verifyDocument(DriverDocument document, bool approved) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin not authenticated')),
      );
      return;
    }

    // Show notes dialog if rejecting
    if (!approved) {
      final shouldReject = await _showNotesDialog(document);
      if (shouldReject != true) return;
    }

    try {
      await _service.verifyDocument(
        driverId: document.driverId,
        documentId: document.id,
        approved: approved,
        adminId: adminId,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'Document approved successfully'
                  : 'Document rejected',
            ),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );
      }

      _notesController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool?> _showNotesDialog(DriverDocument document) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                hintText: 'E.g., Document expired, unclear image...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DriverDocument document;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _DocumentCard({
    required this.document,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = document.isExpiringSoon;
    final isExpired = document.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document type and status
            Row(
              children: [
                Icon(
                  _getDocumentIcon(document.type),
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.type.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Driver ID: ${document.driverId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: document.status.displayName,
                  color: _getStatusColor(document.status),
                ),
              ],
            ),
            const Divider(height: 24),

            // Document details
            _InfoRow(
              icon: Icons.upload_file,
              label: 'Uploaded',
              value: _formatDate(document.uploadedAt),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Expires',
              value: _formatDate(document.expiryDate),
              warning: isExpiringSoon,
              error: isExpired,
            ),

            // Expiry warning
            if (isExpiringSoon || isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error : Icons.warning,
                      color: isExpired ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired
                            ? 'Document has expired'
                            : 'Expires soon (within 30 days)',
                        style: TextStyle(
                          color: isExpired ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDocument(context, document.url),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onVerify,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.license:
        return Icons.badge;
      case DocumentType.medicalCard:
        return Icons.local_hospital;
      case DocumentType.insurance:
        return Icons.shield;
      case DocumentType.certification:
        return Icons.verified;
      case DocumentType.other:
        return Icons.description;
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.valid:
        return Colors.green;
      case DocumentStatus.expiringSoon:
        return Colors.orange;
      case DocumentStatus.expired:
        return Colors.red;
      case DocumentStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _viewDocument(BuildContext context, String url) {
    // TODO: Implement document viewer
    // For now, show URL in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document URL'),
        content: SelectableText(url),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool warning;
  final bool error;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? valueColor;
    if (error) {
      valueColor = Colors.red;
    } else if (warning) {
      valueColor = Colors.orange;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
