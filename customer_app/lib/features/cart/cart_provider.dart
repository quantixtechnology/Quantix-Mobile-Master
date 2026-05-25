import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class CartState {
  final List<CartItemModel> items;
  final bool isLoading;
  final String? error;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get deliveryFee => items.isEmpty ? 0 : 50.0;
  double get total => subtotal + deliveryFee;

  CartState copyWith({
    List<CartItemModel>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      CartState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class CartNotifier extends Notifier<CartState> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  CartState build() => CartState(items: _repo.items);

  Future<void> addProduct(ProductModel product) async {
    await _repo.addItem(product);
    state = state.copyWith(items: _repo.items);
  }

  Future<void> removeProduct(String productId) async {
    await _repo.removeItem(productId);
    state = state.copyWith(items: _repo.items);
  }

  Future<void> decrement(String productId) async {
    await _repo.decrementItem(productId);
    state = state.copyWith(items: _repo.items);
  }

  Future<void> clear() async {
    await _repo.clear();
    state = state.copyWith(items: const []);
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
