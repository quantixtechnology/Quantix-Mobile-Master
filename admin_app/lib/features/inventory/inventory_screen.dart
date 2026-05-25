import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final state = ref.watch(inventoryProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: state.lowStockOnly ? primary : null,
            ),
            tooltip: 'Low stock only',
            onPressed: () =>
                ref.read(inventoryProvider.notifier).toggleLowStockFilter(),
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
                      Text('Failed to load inventory',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.read(inventoryProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? const Center(child: Text('No inventory items'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(inventoryProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final item = state.items[i];
                          final isLow = item.stock < 5;
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isLow
                                    ? Colors.red.shade50
                                    : primary.withAlpha(20),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: isLow ? Colors.red : primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'PKR ${item.product.price.toStringAsFixed(0)}'),
                              trailing: GestureDetector(
                                onTap: () =>
                                    _showStockDialog(context, ref, item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isLow
                                        ? Colors.red.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Stock: ${item.stock}',
                                    style: TextStyle(
                                      color: isLow
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
        ],
        selectedIndex: 2,
        onDestinationSelected: (i) {
          const routes = ['/dashboard', '/orders', '/inventory', '/customers'];
          if (i != 2) context.go(routes[i]);
        },
      ),
    );
  }

  void _showStockDialog(BuildContext context, WidgetRef ref, InventoryItem item) {
    final controller = TextEditingController(text: '${item.stock}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update Stock — ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock quantity'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null) {
                ref
                    .read(inventoryProvider.notifier)
                    .updateStock(item.product.id, qty);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
