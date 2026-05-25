import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'assigned_orders_provider.dart';

final _deliveryDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, orderId) {
  return ref.read(deliveryRepositoryProvider).getDelivery(orderId);
});

class DeliveryOrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final detail = ref.watch(_deliveryDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Order #${orderId.substring(0, 8)}')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (order) => _OrderDetailBody(
          order: order,
          primaryColor: primary,
          onStatusUpdate: (status) =>
              ref.read(assignedOrdersProvider.notifier).updateStatus(
                    order.id,
                    status,
                  ),
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderModel order;
  final Color primaryColor;
  final void Function(String status) onStatusUpdate;

  const _OrderDetailBody({
    required this.order,
    required this.primaryColor,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.address != null)
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(order.address!.label.isNotEmpty
                              ? order.address!.label
                              : 'Delivery Address'),
                          subtitle: Text(order.address!.fullAddress),
                        ),
                        ListTile(
                          leading: const Icon(Icons.navigation_outlined),
                          title: const Text('Navigate'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/map/${order.id}'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Order Items',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: order.items
                        .map((item) => ListTile(
                              title: Text(item.name),
                              subtitle: Text('Qty: ${item.quantity}'),
                              trailing: Text(
                                'PKR ${item.subtotal.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Total'),
                    trailing: Text(
                      'PKR ${order.total.toStringAsFixed(0)}',
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _ActionButtons(
              status: order.status.name,
              primaryColor: primaryColor,
              onStatusUpdate: onStatusUpdate,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String status;
  final Color primaryColor;
  final void Function(String) onStatusUpdate;

  const _ActionButtons({
    required this.status,
    required this.primaryColor,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      'assigned' => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => onStatusUpdate('picked_up'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as Picked Up'),
          ),
        ),
      'picked_up' => SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => onStatusUpdate('delivered'),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Mark as Delivered'),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      'delivered' => const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Order Delivered', style: TextStyle(color: Colors.green)),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
