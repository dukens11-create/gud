import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/load.dart';
import '../../services/document_upload_service.dart';
import '../../services/navigation_service.dart';

class UploadBOLScreen extends StatefulWidget {
  final LoadModel load;

  const UploadBOLScreen({super.key, required this.load});

  @override
  State<UploadBOLScreen> createState() => _UploadBOLScreenState();
}

class _UploadBOLScreenState extends State<UploadBOLScreen> {
  final _uploadService = DocumentUploadService();
  File? _selectedPhoto;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Bill of Lading'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Load info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load: ${widget.load.loadNumber}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('From: ${widget.load.pickupAddress}'),
                    Text('To: ${widget.load.deliveryAddress}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Existing BOL photo (if any)
            if (widget.load.bolPhotoUrl != null) ...[
              Card(
                child: Column(
                  children: [
                    Image.network(
                      widget.load.bolPhotoUrl!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Current BOL',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (widget.load.bolUploadedAt != null)
                            Text(
                              'Uploaded: ${_formatDateTime(widget.load.bolUploadedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _confirmReplacePhoto,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Replace Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Selected photo preview
            if (_selectedPhoto != null) ...[
              Card(
                child: Column(
                  children: [
                    Image.file(
                      _selectedPhoto!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _clearSelectedPhoto,
                            icon: const Icon(Icons.close),
                            label: const Text('Clear'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadPhoto,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Upload progress
            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            if (!_isUploading && _selectedPhoto == null) ...[
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for BOL Photos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Ensure all text is clearly visible\n'
                      '• Capture the entire document\n'
                      '• Use good lighting\n'
                      '• Avoid shadows and glare',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final photo = await _uploadService.takePhoto();
    if (photo != null) {
      setState(() => _selectedPhoto = photo);
    }
  }

  Future<void> _pickFromGallery() async {
    final photo = await _uploadService.pickFromGallery();
    if (photo != null) {
      setState(() => _selectedPhoto = photo);
    }
  }

  void _clearSelectedPhoto() {
    setState(() => _selectedPhoto = null);
  }

  Future<void> _uploadPhoto() async {
    if (_selectedPhoto == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload to Firebase Storage
      final photoUrl = await _uploadService.uploadBOL(
        loadId: widget.load.id,
        driverId: widget.load.driverId,
        photo: _selectedPhoto!,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Update Firestore
      await _uploadService.updateLoadBOL(
        loadId: widget.load.id,
        photoUrl: photoUrl,
      );

      if (mounted) {
        NavigationService.showSuccess('BOL uploaded successfully');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        NavigationService.showError('Failed to upload BOL: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _confirmReplacePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace BOL Photo?'),
        content: const Text(
          'Are you sure you want to replace the existing BOL photo? '
          'The old photo will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete old photo
      if (widget.load.bolPhotoUrl != null) {
        await _uploadService.deletePhoto(widget.load.bolPhotoUrl!);
      }
      // User can now select new photo
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
