import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartState {
  final bool isLoading;
  final String? error;
  final int itemCount;
  final double total;

  const CartState({
    this.isLoading = false,
    this.error,
    this.itemCount = 0,
    this.total = 0.0,
  });

  CartState copyWith({
    bool? isLoading,
    String? error,
    int? itemCount,
    double? total,
  }) =>
      CartState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        itemCount: itemCount ?? this.itemCount,
        total: total ?? this.total,
      );
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
