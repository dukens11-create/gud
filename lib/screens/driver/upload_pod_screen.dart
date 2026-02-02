import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/load.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_textfield.dart';

class UploadPODScreen extends StatefulWidget {
  final LoadModel load;

  const UploadPODScreen({super.key, required this.load});

  @override
  State<UploadPODScreen> createState() => _UploadPODScreenState();
}

class _UploadPODScreenState extends State<UploadPODScreen> {
  final _storageService = StorageService();
  final _firestoreService = FirestoreService();
  final _notesController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _storageService.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _errorMessage = null;
      });
    }
  }

  Future<void> _uploadPOD() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Please select an image first');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Upload image to Firebase Storage
      final imageUrl = await _storageService.uploadPodImage(
        loadId: widget.load.id,
        file: _selectedImage!,
      );

      // Save POD to Firestore
      await _firestoreService.addPod(
        loadId: widget.load.id,
        imageUrl: imageUrl,
        notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        uploadedBy: currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('POD uploaded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Proof of Delivery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Load info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.load.loadNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Delivery: ${widget.load.deliveryAddress}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image preview or picker
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes field
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Upload button
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : AppButton(
                    label: 'Upload POD',
                    onPressed: _uploadPOD,
                  ),
          ],
        ),
      ),
    );
  }
}
