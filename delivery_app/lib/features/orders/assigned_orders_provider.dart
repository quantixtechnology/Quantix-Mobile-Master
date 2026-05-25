import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class AssignedOrdersState {
  final List<OrderModel> orders;
  final bool isLoading;
  final String? error;

  const AssignedOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  AssignedOrdersState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AssignedOrdersState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AssignedOrdersNotifier extends Notifier<AssignedOrdersState> {
  DeliveryRepository get _repo => ref.read(deliveryRepositoryProvider);

  @override
  AssignedOrdersState build() {
    _load();
    return const AssignedOrdersState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final orders = await _repo.getAssignedOrders();
      state = state.copyWith(orders: orders, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();

  Future<void> updateStatus(
    String orderId,
    String status, {
    double? lat,
    double? lng,
  }) async {
    try {
      await _repo.updateStatus(orderId, status, lat: lat, lng: lng);
      await _load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final assignedOrdersProvider =
    NotifierProvider<AssignedOrdersNotifier, AssignedOrdersState>(
        AssignedOrdersNotifier.new);
