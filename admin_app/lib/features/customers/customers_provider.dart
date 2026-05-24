import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerRecord {
  final String id;
  final String name;
  final String phone;
  final int totalOrders;

  const CustomerRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
  });
}

class CustomersState {
  final bool isLoading;
  final List<CustomerRecord> customers;
  final String? searchQuery;
  final String? error;

  const CustomersState({
    this.isLoading = false,
    this.customers = const [],
    this.searchQuery,
    this.error,
  });

  CustomersState copyWith({
    bool? isLoading,
    List<CustomerRecord>? customers,
    String? searchQuery,
    String? error,
  }) =>
      CustomersState(
        isLoading: isLoading ?? this.isLoading,
        customers: customers ?? this.customers,
        searchQuery: searchQuery ?? this.searchQuery,
        error: error,
      );
}

class CustomersNotifier extends Notifier<CustomersState> {
  @override
  CustomersState build() => const CustomersState();
}

final customersProvider =
    NotifierProvider<CustomersNotifier, CustomersState>(CustomersNotifier.new);
