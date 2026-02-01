import 'package:flutter/material.dart';
import '../../models/load.dart';

class AdminLoadDetail extends StatefulWidget {
  final LoadModel load;

  const AdminLoadDetail({
    super.key,
    required this.load,
  });

  @override
  State<AdminLoadDetail> createState() => _AdminLoadDetailState();
}

class _AdminLoadDetailState extends State<AdminLoadDetail> {
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
