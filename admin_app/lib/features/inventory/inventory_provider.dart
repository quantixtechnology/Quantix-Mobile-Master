import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryItem {
  final String id;
  final String name;
  final int stockCount;
  final double price;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.stockCount,
    required this.price,
  });
}

class InventoryState {
  final bool isLoading;
  final List<InventoryItem> items;
  final String? error;

  const InventoryState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItem>? items,
    String? error,
  }) =>
      InventoryState(
        isLoading: isLoading ?? this.isLoading,
        items: items ?? this.items,
        error: error,
      );
}

class InventoryNotifier extends Notifier<InventoryState> {
  @override
  InventoryState build() => const InventoryState();
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, InventoryState>(InventoryNotifier.new);
