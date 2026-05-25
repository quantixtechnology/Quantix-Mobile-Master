import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AdminOrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? statusFilter;
  final String? error;

  const AdminOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.statusFilter,
    this.error,
  });

  AdminOrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? statusFilter,
    bool clearFilter = false,
    String? error,
    bool clearError = false,
  }) =>
      AdminOrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        statusFilter:
            clearFilter ? null : (statusFilter ?? this.statusFilter),
        error: clearError ? null : (error ?? this.error),
      );
}

class AdminOrdersNotifier extends Notifier<AdminOrdersState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  AdminOrdersState build() {
    _load();
    return const AdminOrdersState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final orders = await _repo.getOrders(status: state.statusFilter);
      state = state.copyWith(orders: orders, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> filterByStatus(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearFilter: status == null,
      isLoading: true,
    );
    await _load();
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      final updated = await _repo.updateOrderStatus(orderId, status);
      final idx = state.orders.indexWhere((o) => o.id == orderId);
      if (idx >= 0) {
        final orders = List<OrderModel>.of(state.orders);
        orders[idx] = updated;
        state = state.copyWith(orders: orders);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final adminOrdersProvider =
    NotifierProvider<AdminOrdersNotifier, AdminOrdersState>(
        AdminOrdersNotifier.new);
