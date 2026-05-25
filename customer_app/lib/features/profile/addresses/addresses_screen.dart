import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

final _addressesProvider = FutureProvider<List<AddressModel>>((ref) {
  return ref.read(profileRepositoryProvider).getAddresses();
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final addressesAsync = ref.watch(_addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses')),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load addresses'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(_addressesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (addresses) => addresses.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No saved addresses'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final addr = addresses[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary.withAlpha(20),
                        child: Icon(Icons.location_on, color: primary, size: 20),
                      ),
                      title: Text(addr.label.isNotEmpty ? addr.label : 'Address ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(addr.fullAddress),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Address'),
        content: const Text('Address management coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
