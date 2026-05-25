import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(active: true),
            _OrdersList(active: false),
          ],
        ),
        bottomNavigationBar: Consumer(
          builder: (context, ref, _) => NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Catalog'),
              NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
            selectedIndex: 2,
            onDestinationSelected: (i) {
              const routes = ['/home', '/catalog', '/orders', '/profile'];
              if (i != 2) context.go(routes[i]);
            },
          ),
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  final bool active;

  const _OrdersList({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final orders = active ? orderState.activeOrders : orderState.history;

    if (orderState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orderState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load orders', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(orderProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (orders.isEmpty) {
      return Center(
        child: Text(active ? 'No active orders' : 'No order history'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(orderProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

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
                  Text('#${order.id.substring(0, 8)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}  •  PKR ${order.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      OrderStatus.delivered => (Colors.green.shade700, Colors.green.shade50),
      OrderStatus.cancelled => (Colors.red.shade700, Colors.red.shade50),
      OrderStatus.dispatched => (Colors.blue.shade700, Colors.blue.shade50),
      OrderStatus.preparing => (Colors.orange.shade700, Colors.orange.shade50),
      _ => (Colors.grey.shade700, Colors.grey.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
