import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final bool lowStockOnly;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.lowStockOnly = false,
    this.error,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    bool? lowStockOnly,
    String? error,
    bool clearError = false,
  }) =>
      InventoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        lowStockOnly: lowStockOnly ?? this.lowStockOnly,
        error: clearError ? null : (error ?? this.error),
      );
}

class InventoryNotifier extends Notifier<InventoryState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  InventoryState build() {
    _load();
    return const InventoryState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final items = await _repo.getInventory(
        lowStock: state.lowStockOnly ? true : null,
      );
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleLowStockFilter() {
    state = state.copyWith(
      lowStockOnly: !state.lowStockOnly,
      isLoading: true,
    );
    _load();
  }

  Future<void> updateStock(String id, int stock) async {
    try {
      final updated = await _repo.updateInventory(id, stock: stock);
      final idx = state.items.indexWhere((i) => i.product.id == id);
      if (idx >= 0) {
        final items = List<InventoryItem>.of(state.items);
        items[idx] = InventoryItem(product: updated, stock: stock);
        state = state.copyWith(items: items);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);
