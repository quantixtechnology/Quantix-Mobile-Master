import 'package:flutter/material.dart';

class AssignedOrdersScreen extends StatelessWidget {
  const AssignedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Orders')),
      body: const Center(child: Text('No orders assigned')),
    );
  }
}
