import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../../auth/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final auth = ref.watch(authProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: primary.withAlpha(15),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: primary,
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Customer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user?.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(user!.phone,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
                if (user?.email != null) ...[
                  const SizedBox(height: 2),
                  Text(user!.email!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ProfileTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            onTap: () => context.go('/orders'),
          ),
          _ProfileTile(
            icon: Icons.location_on_outlined,
            title: 'My Addresses',
            onTap: () => context.push('/addresses'),
          ),
          _ProfileTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          const Divider(height: 1),
          _ProfileTile(
            icon: Icons.logout,
            title: 'Sign Out',
            color: Colors.red,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedIndex: 3,
        onDestinationSelected: (i) {
          const routes = ['/home', '/catalog', '/orders', '/profile'];
          if (i != 3) context.go(routes[i]);
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
