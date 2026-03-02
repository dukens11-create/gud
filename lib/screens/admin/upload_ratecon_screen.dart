import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/load.dart';
import '../../services/document_upload_service.dart';
import '../../services/navigation_service.dart';
import '../../utils/datetime_utils.dart';

/// Screen for admins to upload a rate confirmation (ratecon) document for a load.
///
/// Supports:
/// - Camera photo capture
/// - Gallery image selection
/// - Document file selection (PDF, DOCX)
///
/// On successful upload, updates the load in Firestore and sends a notification
/// to the assigned driver via the Cloud Function trigger on `rateconUrl`.
class UploadRateconScreen extends StatefulWidget {
  final LoadModel load;

  const UploadRateconScreen({super.key, required this.load});

  @override
  State<UploadRateconScreen> createState() => _UploadRateconScreenState();
}

class _UploadRateconScreenState extends State<UploadRateconScreen> {
  final _uploadService = DocumentUploadService();

  File? _selectedFile;
  String? _selectedFileName;
  bool _isImage = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Rate Confirmation'),
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
                    const SizedBox(height: 4),
                    Text('Driver: ${widget.load.driverName ?? widget.load.driverId}'),
                    const SizedBox(height: 4),
                    Text('From: ${widget.load.pickupAddress}'),
                    Text('To: ${widget.load.deliveryAddress}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Existing ratecon (if any)
            if (widget.load.rateconUrl != null) ...[
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Ratecon Already Uploaded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      if (widget.load.rateconFileName != null) ...[
                        const SizedBox(height: 8),
                        Text('File: ${widget.load.rateconFileName}'),
                      ],
                      if (widget.load.rateconUploadedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Uploaded: ${DateTimeUtils.formatDisplayDateTime(widget.load.rateconUploadedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (widget.load.rateconSentStatus == 'sent') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.send, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Sent to driver',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'You can upload a new ratecon to replace the existing one.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Selected file preview
            if (_selectedFile != null) ...[
              Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isImage)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.file(
                          _selectedFile!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              size: 48,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFileName ?? 'Selected File',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Ready to upload',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _clearSelectedFile,
                            icon: const Icon(Icons.close),
                            label: const Text('Clear'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadFile,
                            icon: const Icon(Icons.cloud_upload),
                            label: const Text('Upload & Send to Driver'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload progress
            if (_isUploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            if (!_isUploading && _selectedFile == null) ...[
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document (PDF, DOCX)'),
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
                          'About Rate Confirmation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• The driver will be notified automatically after upload\n'
                      '• Accepted formats: JPG, PNG, PDF, DOCX\n'
                      '• Maximum file size: 20 MB\n'
                      '• The driver can view the ratecon in their load details',
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
      setState(() {
        _selectedFile = photo;
        _selectedFileName = 'ratecon_photo.jpg';
        _isImage = true;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final photo = await _uploadService.pickFromGallery();
    if (photo != null) {
      setState(() {
        _selectedFile = photo;
        _selectedFileName = 'ratecon_image.jpg';
        _isImage = true;
      });
    }
  }

  Future<void> _pickDocument() async {
    final platformFile = await _uploadService.pickDocumentFile();
    if (platformFile != null && platformFile.path != null) {
      final extension = (platformFile.extension ?? '').toLowerCase();
      setState(() {
        _selectedFile = File(platformFile.path!);
        _selectedFileName = platformFile.name;
        _isImage = extension == 'jpg' || extension == 'jpeg' || extension == 'png';
      });
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _isImage = false;
    });
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedFileName == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload file to Firebase Storage
      final fileUrl = await _uploadService.uploadRatecon(
        loadId: widget.load.id,
        file: _selectedFile!,
        fileName: _selectedFileName!,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Update Firestore (triggers Cloud Function notification to driver)
      await _uploadService.updateLoadRatecon(
        loadId: widget.load.id,
        fileUrl: fileUrl,
        fileName: _selectedFileName!,
      );

      if (mounted) {
        NavigationService.showSuccess(
          'Ratecon uploaded and driver notified successfully',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        NavigationService.showError('Failed to upload ratecon: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}
