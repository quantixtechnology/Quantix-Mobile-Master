import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load order'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (order) => _OrderBody(order: order, primaryColor: primary),
      ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  final OrderModel order;
  final Color primaryColor;

  const _OrderBody({required this.order, required this.primaryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #${order.id.substring(0, 8)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      _StatusChip(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Placed ${_formatDate(order.createdAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionTitle('Items'),
          Card(
            child: Column(
              children: order.items
                  .map((item) => ListTile(
                        title: Text(item.name),
                        subtitle: Text('Qty: ${item.quantity}'),
                        trailing: Text('PKR ${item.subtotal.toStringAsFixed(0)}'),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (order.address != null) ...[
            _SectionTitle('Delivery Address'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(order.address!.label.isNotEmpty
                    ? order.address!.label
                    : 'Address'),
                subtitle: Text(order.address!.fullAddress),
              ),
            ),
            const SizedBox(height: 12),
          ],
          _SectionTitle('Order Summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow('Subtotal',
                      'PKR ${(order.total - 50).clamp(0, double.infinity).toStringAsFixed(0)}'),
                  const SizedBox(height: 4),
                  const _SummaryRow('Delivery fee', 'PKR 50'),
                  const Divider(height: 16),
                  _SummaryRow('Total', 'PKR ${order.total.toStringAsFixed(0)}',
                      bold: true),
                ],
              ),
            ),
          ),
          if (order.status.isActive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/tracking/${order.id}'),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Track Order'),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
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
      child: Text(status.label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
