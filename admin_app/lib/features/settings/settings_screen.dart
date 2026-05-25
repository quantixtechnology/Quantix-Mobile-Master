import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../auth/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final auth = ref.watch(adminAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (auth.user != null)
            ListTile(
              leading: CircleAvatar(
                child: Text(auth.user!.name.isNotEmpty
                    ? auth.user!.name[0].toUpperCase()
                    : 'A'),
              ),
              title: Text(auth.user!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(auth.user!.email ?? auth.user!.phone),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Business'),
            subtitle: Text(brand.appName),
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Currency'),
            subtitle: Text(brand.currency),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
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
                await ref.read(adminAuthProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
