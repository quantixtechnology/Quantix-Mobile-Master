import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class OrderState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;

  const OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  List<OrderModel> get activeOrders =>
      orders.where((o) => o.status.isActive).toList();

  List<OrderModel> get history =>
      orders.where((o) => !o.status.isActive).toList();

  OrderState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      OrderState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class OrderNotifier extends Notifier<OrderState> {
  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  @override
  OrderState build() {
    _load();
    return const OrderState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final orders = await _repo.getOrders();
      state = state.copyWith(orders: orders, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<bool> placeOrder({
    required List<CartItemModel> cartItems,
    required String addressId,
    String paymentMethod = 'cash',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = cartItems
          .map((i) => {'productId': i.product.id, 'qty': i.quantity})
          .toList();
      final order = await _repo.placeOrder(
        items: items,
        addressId: addressId,
        paymentMethod: paymentMethod,
      );
      state = state.copyWith(
        orders: [order, ...state.orders],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> cancelOrder(String id, String reason) async {
    try {
      final updated = await _repo.cancelOrder(id, reason);
      final idx = state.orders.indexWhere((o) => o.id == id);
      if (idx >= 0) {
        final orders = List<OrderModel>.of(state.orders);
        orders[idx] = updated;
        state = state.copyWith(orders: orders);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final orderProvider =
    NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);

final orderDetailProvider =
    FutureProvider.family<OrderModel, String>((ref, id) {
  return ref.read(orderRepositoryProvider).getOrder(id);
});
