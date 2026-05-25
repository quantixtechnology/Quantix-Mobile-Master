import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: primary.withAlpha(15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: primary),
                      const SizedBox(width: 8),
                      Text('Sales Analytics',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detailed analytics with charts will be available in the next release.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _AnalyticsTile(
            icon: Icons.trending_up,
            title: 'Revenue Trends',
            subtitle: 'Daily, weekly, and monthly revenue',
            color: Colors.green,
          ),
          _AnalyticsTile(
            icon: Icons.people_outline,
            title: 'Customer Growth',
            subtitle: 'New vs returning customers',
            color: Colors.blue,
          ),
          _AnalyticsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Top Products',
            subtitle: 'Best-selling items by volume',
            color: primary,
          ),
          _AnalyticsTile(
            icon: Icons.delivery_dining_outlined,
            title: 'Delivery Performance',
            subtitle: 'Average delivery time and ratings',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AnalyticsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(20),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
