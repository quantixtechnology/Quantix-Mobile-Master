import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../catalog_provider.dart';
import '../../cart/cart_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));
    final detail = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load product'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(productDetailProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) => _ProductBody(product: product, primaryColor: primary),
      ),
    );
  }
}

class _ProductBody extends ConsumerWidget {
  final ProductModel product;
  final Color primaryColor;

  const _ProductBody({required this.product, required this.primaryColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).items;
    final qtyInCart = cartItems
        .where((i) => i.product.id == product.id)
        .fold(0, (sum, i) => sum + i.quantity);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: product.image != null
                      ? Image.network(product.image!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: primaryColor.withAlpha(20),
                            child: Icon(Icons.image_outlined, size: 80, color: primaryColor),
                          ))
                      : Container(
                          color: primaryColor.withAlpha(20),
                          child: Center(
                              child: Icon(Icons.image_outlined, size: 80, color: primaryColor)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${product.currency} ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.inStock
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.inStock
                              ? 'In Stock (${product.stock})'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: product.inStock
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'No description available.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: product.inStock
                ? qtyInCart > 0
                    ? Row(
                        children: [
                          IconButton.outlined(
                            icon: const Icon(Icons.remove),
                            onPressed: () =>
                                ref.read(cartProvider.notifier).decrement(product.id),
                          ),
                          const SizedBox(width: 12),
                          Text('$qtyInCart',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            icon: const Icon(Icons.add),
                            onPressed: () =>
                                ref.read(cartProvider.notifier).addProduct(product),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => context.push('/cart'),
                              child: const Text('View Cart'),
                            ),
                          ),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              ref.read(cartProvider.notifier).addProduct(product),
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add to Cart'),
                        ),
                      )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      child: const Text('Out of Stock'),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
