import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final dash = ref.watch(dashboardProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: Text('${brand.appName} Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: dash.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dash.error != null)
                      Card(
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.error_outline, color: Colors.red),
                          title: Text(dash.error!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          title: "Today's Orders",
                          value: '${dash.stats?.todayOrders ?? 0}',
                          icon: Icons.receipt_long_outlined,
                          color: primary,
                          onTap: () => context.go('/orders'),
                        ),
                        _StatCard(
                          title: 'Revenue',
                          value: 'PKR ${(dash.stats?.revenue ?? 0).toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          onTap: () => context.go('/analytics'),
                        ),
                        _StatCard(
                          title: 'Pending Orders',
                          value: '${dash.stats?.pendingOrders ?? 0}',
                          icon: Icons.pending_outlined,
                          color: Colors.orange,
                          onTap: () => context.go('/orders'),
                        ),
                        _StatCard(
                          title: 'Active Riders',
                          value: '${dash.stats?.activeRiders ?? 0}',
                          icon: Icons.delivery_dining_outlined,
                          color: Colors.blue,
                          onTap: () => context.go('/delivery'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Quick Actions',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _QuickAction(
                      icon: Icons.inventory_2_outlined,
                      title: 'Manage Inventory',
                      subtitle: 'Update stock and prices',
                      onTap: () => context.go('/inventory'),
                    ),
                    _QuickAction(
                      icon: Icons.people_outline,
                      title: 'Customers',
                      subtitle: 'View customer list',
                      onTap: () => context.go('/customers'),
                    ),
                    _QuickAction(
                      icon: Icons.bar_chart_outlined,
                      title: 'Analytics',
                      subtitle: 'Sales and performance',
                      onTap: () => context.go('/analytics'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          const routes = ['/dashboard', '/orders', '/inventory', '/customers'];
          if (i != 0) context.go(routes[i]);
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
