import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssignedOrder {
  final String id;
  final String customerName;
  final String address;
  final String status;

  const AssignedOrder({
    required this.id,
    required this.customerName,
    required this.address,
    required this.status,
  });
}

class AssignedOrdersState {
  final bool isLoading;
  final List<AssignedOrder> orders;
  final String? error;

  const AssignedOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  AssignedOrdersState copyWith({
    bool? isLoading,
    List<AssignedOrder>? orders,
    String? error,
  }) =>
      AssignedOrdersState(
        isLoading: isLoading ?? this.isLoading,
        orders: orders ?? this.orders,
        error: error,
      );
}

class AssignedOrdersNotifier extends Notifier<AssignedOrdersState> {
  @override
  AssignedOrdersState build() => const AssignedOrdersState();

  void updateOrderStatus(String orderId, String status) {
    final updated = state.orders
        .map((o) => o.id == orderId
            ? AssignedOrder(
                id: o.id,
                customerName: o.customerName,
                address: o.address,
                status: status,
              )
            : o)
        .toList();
    state = state.copyWith(orders: updated);
  }
}

final assignedOrdersProvider =
    NotifierProvider<AssignedOrdersNotifier, AssignedOrdersState>(
        AssignedOrdersNotifier.new);
