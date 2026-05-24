import 'package:flutter/material.dart';

class DeliveryMapScreen extends StatelessWidget {
  final String orderId;

  const DeliveryMapScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigate — Order #$orderId')),
      body: const Center(child: Text('Map View')),
    );
  }
}
