import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminOrder {
  final String id;
  final String customerName;
  final String status;
  final double total;

  const AdminOrder({
    required this.id,
    required this.customerName,
    required this.status,
    required this.total,
  });
}

class AdminOrdersState {
  final bool isLoading;
  final List<AdminOrder> orders;
  final String? error;

  const AdminOrdersState({
    this.isLoading = false,
    this.orders = const [],
    this.error,
  });

  AdminOrdersState copyWith({
    bool? isLoading,
    List<AdminOrder>? orders,
    String? error,
  }) =>
      AdminOrdersState(
        isLoading: isLoading ?? this.isLoading,
        orders: orders ?? this.orders,
        error: error,
      );
}

class AdminOrdersNotifier extends Notifier<AdminOrdersState> {
  @override
  AdminOrdersState build() => const AdminOrdersState();

  void updateStatus(String orderId, String status) {
    final updated = state.orders
        .map((o) => o.id == orderId
            ? AdminOrder(
                id: o.id,
                customerName: o.customerName,
                status: status,
                total: o.total,
              )
            : o)
        .toList();
    state = state.copyWith(orders: updated);
  }
}

final adminOrdersProvider =
    NotifierProvider<AdminOrdersNotifier, AdminOrdersState>(
        AdminOrdersNotifier.new);
