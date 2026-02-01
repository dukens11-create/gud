import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload POD'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Firebase configuration required',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
