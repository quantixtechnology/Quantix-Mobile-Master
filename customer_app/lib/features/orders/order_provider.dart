import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderState {
  final bool isLoading;
  final String? error;

  const OrderState({this.isLoading = false, this.error});

  OrderState copyWith({bool? isLoading, String? error}) => OrderState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() => const OrderState();
}

final orderProvider =
    NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);
