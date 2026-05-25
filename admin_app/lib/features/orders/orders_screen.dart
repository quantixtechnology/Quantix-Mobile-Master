import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'orders_provider.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  static const _statuses = ['All', 'pending', 'confirmed', 'preparing', 'dispatched', 'delivered', 'cancelled'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final s = _statuses[i];
                final selected = i == 0
                    ? state.statusFilter == null
                    : state.statusFilter == s;
                return FilterChip(
                  label: Text(s == 'All' ? 'All' : _capitalize(s)),
                  selected: selected,
                  onSelected: (_) => ref.read(adminOrdersProvider.notifier)
                      .filterByStatus(i == 0 ? null : s),
                );
              },
            ),
          ),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (i) {
          const routes = ['/dashboard', '/orders', '/inventory', '/customers'];
          if (i != 1) context.go(routes[i]);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AdminOrdersState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load orders',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(adminOrdersProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.orders.isEmpty) return const Center(child: Text('No orders found'));
    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final order = state.orders[i];
          return Card(
            child: ListTile(
              title: Text('#${order.id.substring(0, 8)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${order.items.length} items  •  PKR ${order.total.toStringAsFixed(0)}'),
              trailing: _StatusDropdown(
                currentStatus: order.status.name,
                onChanged: (s) =>
                    ref.read(adminOrdersProvider.notifier).updateStatus(order.id, s),
              ),
            ),
          );
        },
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}

class _StatusDropdown extends StatelessWidget {
  final String currentStatus;
  final void Function(String) onChanged;

  const _StatusDropdown({required this.currentStatus, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const statuses = ['pending', 'confirmed', 'preparing', 'dispatched', 'delivered', 'cancelled'];
    return DropdownButton<String>(
      value: currentStatus,
      underline: const SizedBox.shrink(),
      items: statuses
          .map((s) => DropdownMenuItem(
                value: s,
                child: Text(s[0].toUpperCase() + s.substring(1),
                    style: const TextStyle(fontSize: 12)),
              ))
          .toList(),
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}
