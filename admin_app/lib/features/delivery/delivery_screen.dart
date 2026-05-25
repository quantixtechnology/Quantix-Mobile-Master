import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'delivery_provider.dart';

class DeliveryManagementScreen extends ConsumerWidget {
  const DeliveryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryManagementProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Management')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load riders',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.read(deliveryManagementProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : state.riders.isEmpty
                  ? const Center(child: Text('No riders available'))
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(deliveryManagementProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.riders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final rider = state.riders[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: rider.isActive
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: rider.isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                              title: Text(rider.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(rider.isActive
                                  ? rider.activeOrderId != null
                                      ? 'Delivering order #${rider.activeOrderId!.substring(0, 8)}'
                                      : 'Online — Available'
                                  : 'Offline'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rider.isActive
                                      ? Colors.green.shade50
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rider.isActive ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: rider.isActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
