import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quantix_shared/quantix_shared.dart';
import '../catalog_provider.dart';
import '../../cart/cart_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = ref.watch(brandConfigProvider);
    final catalog = ref.watch(catalogProvider);
    final cartCount = ref.watch(cartProvider).itemCount;
    final primary = Color(int.parse(brand.primaryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(catalogProvider.notifier).search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (v) => ref.read(catalogProvider.notifier).search(v),
            ),
          ),
          if (catalog.categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: catalog.categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return FilterChip(
                      label: const Text('All'),
                      selected: catalog.selectedCategoryId == null,
                      onSelected: (_) =>
                          ref.read(catalogProvider.notifier).filterByCategory(null),
                    );
                  }
                  final cat = catalog.categories[i - 1];
                  return FilterChip(
                    label: Text(cat.name),
                    selected: catalog.selectedCategoryId == cat.id,
                    selectedColor: primary.withAlpha(40),
                    onSelected: (_) =>
                        ref.read(catalogProvider.notifier).filterByCategory(cat.id),
                  );
                },
              ),
            ),
          Expanded(child: _buildBody(context, catalog, primary)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (i) {
          const routes = ['/home', '/catalog', '/orders', '/profile'];
          if (i != 1) context.go(routes[i]);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CatalogState catalog, Color primary) {
    if (catalog.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load products', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.read(catalogProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (catalog.products.isEmpty) {
      return const Center(child: Text('No products found'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(catalogProvider.notifier).refresh(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: catalog.products.length,
        itemBuilder: (context, i) {
          final product = catalog.products[i];
          return _ProductTile(product: product, primaryColor: primary);
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final Color primaryColor;

  const _ProductTile({required this.product, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.image != null
                      ? Image.network(product.image!, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: primaryColor.withAlpha(20),
                            child: Icon(Icons.image_outlined, color: primaryColor),
                          ))
                      : Container(
                          color: primaryColor.withAlpha(20),
                          child: Center(child: Icon(Icons.image_outlined, color: primaryColor)),
                        ),
                  if (!product.inStock)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text('Out of Stock',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${product.currency} ${product.price.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
