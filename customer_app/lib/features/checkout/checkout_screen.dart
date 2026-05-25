import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../cart/cart_provider.dart';
import '../orders/order_provider.dart';

final _checkoutAddressesProvider = FutureProvider<List<AddressModel>>((ref) {
  return ref.read(profileRepositoryProvider).getAddresses();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedAddressId;
  String _paymentMethod = 'cash';
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final cart = ref.watch(cartProvider);
    final addressesAsync = ref.watch(_checkoutAddressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load addresses'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(_checkoutAddressesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (addresses) {
          _selectedAddressId ??= addresses.isNotEmpty ? addresses.first.id : null;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionTitle('Order Summary'),
                    Card(
                      child: Column(
                        children: [
                          ...cart.items.map((item) => ListTile(
                                title: Text(item.product.name),
                                subtitle: Text('Qty: ${item.quantity}'),
                                trailing: Text(
                                    '${brand.currency} ${item.subtotal.toStringAsFixed(0)}'),
                              )),
                          const Divider(height: 1),
                          ListTile(
                            title: const Text('Delivery fee'),
                            trailing: Text(
                                '${brand.currency} ${cart.deliveryFee.toStringAsFixed(0)}'),
                          ),
                          ListTile(
                            title: const Text('Total',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text(
                              '${brand.currency} ${cart.total.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('Delivery Address'),
                    if (addresses.isEmpty)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.add_location_outlined),
                          title: const Text('No addresses saved'),
                          subtitle: const Text('Add one from your profile'),
                          onTap: () => context.push('/addresses'),
                        ),
                      )
                    else
                      Card(
                        child: RadioGroup<String>(
                          groupValue: _selectedAddressId ?? addresses.first.id,
                          onChanged: (v) =>
                              setState(() => _selectedAddressId = v),
                          child: Column(
                            children: addresses
                                .map((addr) => RadioListTile<String>(
                                      value: addr.id,
                                      title: Text(addr.label.isNotEmpty
                                          ? addr.label
                                          : 'Address'),
                                      subtitle: Text(addr.fullAddress),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _SectionTitle('Payment Method'),
                    Card(
                      child: RadioGroup<String>(
                        groupValue: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                        child: Column(
                          children: const [
                            RadioListTile<String>(
                              value: 'cash',
                              title: Text('Cash on Delivery'),
                              secondary: Icon(Icons.money),
                            ),
                            RadioListTile<String>(
                              value: 'card',
                              title: Text('Card'),
                              secondary: Icon(Icons.credit_card),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (_isPlacing || _selectedAddressId == null)
                              ? null
                              : _placeOrder,
                      child: _isPlacing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Place Order — ${brand.currency} ${cart.total.toStringAsFixed(0)}'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacing = true);
    final cart = ref.read(cartProvider);

    final success = await ref.read(orderProvider.notifier).placeOrder(
          cartItems: cart.items,
          addressId: _selectedAddressId!,
          paymentMethod: _paymentMethod,
        );

    if (!mounted) return;
    setState(() => _isPlacing = false);

    if (success) {
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('/orders');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } else {
      final error = ref.read(orderProvider).error ?? 'Failed to place order';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
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
