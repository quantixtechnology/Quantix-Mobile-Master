import 'package:flutter/material.dart';

class DeliveryManagementScreen extends StatelessWidget {
  const DeliveryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Management')),
      body: const Center(child: Text('Riders & Dispatch')),
    );
  }
}
