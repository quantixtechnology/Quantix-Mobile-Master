import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  final String trackingId;

  const TrackingScreen({super.key, required this.trackingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking')),
      body: Center(child: Text('Tracking Screen\nID: $trackingId')),
    );
  }
}
