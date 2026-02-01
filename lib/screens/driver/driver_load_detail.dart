import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/load.dart';
import '../../widgets/app_button.dart';
import 'upload_pod_screen.dart';

class DriverLoadDetail extends StatefulWidget {
  final LoadModel load;

  const DriverLoadDetail({
    super.key,
    required this.load,
  });

  @override
  State<DriverLoadDetail> createState() => _DriverLoadDetailState();
}

class _DriverLoadDetailState extends State<DriverLoadDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load #${widget.load.loadNumber}'),
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
