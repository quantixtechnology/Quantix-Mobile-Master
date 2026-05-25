import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../auth/auth_provider.dart';

class DeliveryProfileScreen extends ConsumerWidget {
  const DeliveryProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final auth = ref.watch(deliveryAuthProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
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
                        : 'R',
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Rider',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user?.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(user!.phone,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rider',
                    style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(deliveryAuthProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
