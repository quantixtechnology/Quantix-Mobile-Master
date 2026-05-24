import 'package:flutter/material.dart';

class DeliveryOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: const Center(child: Text('Order Details')),
    );
  }
}
