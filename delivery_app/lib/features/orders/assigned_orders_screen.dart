import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'assigned_orders_provider.dart';

class AssignedOrdersScreen extends ConsumerWidget {
  const AssignedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final state = ref.watch(assignedOrdersProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: Text('${brand.appName} Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => context.push('/earnings'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load orders',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.read(assignedOrdersProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No assigned orders'),
                          const SizedBox(height: 8),
                          const Text('New orders will appear here',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(assignedOrdersProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final order = state.orders[i];
                          return _OrderCard(order: order, primaryColor: primary);
                        },
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Color primaryColor;

  const _OrderCard({required this.order, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  _DeliveryStatusChip(status: order.status.name),
                ],
              ),
              const SizedBox(height: 8),
              if (order.address != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.address!.fullAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'PKR ${order.total.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryStatusChip extends StatelessWidget {
  final String status;

  const _DeliveryStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'delivered' => (Colors.green.shade700, Colors.green.shade50),
      'picked_up' => (Colors.blue.shade700, Colors.blue.shade50),
      'en_route' => (Colors.orange.shade700, Colors.orange.shade50),
      _ => (Colors.grey.shade700, Colors.grey.shade100),
    };
    final label = switch (status) {
      'picked_up' => 'Picked Up',
      'en_route' => 'En Route',
      'delivered' => 'Delivered',
      'assigned' => 'Assigned',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
