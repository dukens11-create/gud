import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_textfield.dart';

class UploadPodScreen extends StatefulWidget {
  final String loadId;

  const UploadPodScreen({
    super.key,
    required this.loadId,
  });

  @override
  State<UploadPodScreen> createState() => _UploadPodScreenState();
}

class _UploadPodScreenState extends State<UploadPodScreen> {
  final _notesController = TextEditingController();
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();
  
  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  Future<void> _uploadPOD() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture an image first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadPODImage(
        _imageFile!,
        widget.loadId,
      );

      // Save POD data to Firestore
      await _firestoreService.addPOD(
        loadId: widget.loadId,
        imageUrl: imageUrl,
        notes: _notesController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('POD uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading POD: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload POD'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No image captured',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppButton(
              text: _imageFile == null ? 'Capture Photo' : 'Retake Photo',
              onPressed: _captureImage,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Notes (Optional)',
              controller: _notesController,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Upload POD',
              onPressed: _uploadPOD,
              isLoading: _isLoading,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
