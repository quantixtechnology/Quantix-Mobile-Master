import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class CustomersState {
  final List<UserModel> customers;
  final bool isLoading;
  final String searchQuery;
  final String? error;

  const CustomersState({
    this.customers = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.error,
  });

  CustomersState copyWith({
    List<UserModel>? customers,
    bool? isLoading,
    String? searchQuery,
    String? error,
    bool clearError = false,
  }) =>
      CustomersState(
        customers: customers ?? this.customers,
        isLoading: isLoading ?? this.isLoading,
        searchQuery: searchQuery ?? this.searchQuery,
        error: clearError ? null : (error ?? this.error),
      );
}

class CustomersNotifier extends Notifier<CustomersState> {
  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  @override
  CustomersState build() {
    _load();
    return const CustomersState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final customers = await _repo.getCustomers(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(customers: customers, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) {
    state = state.copyWith(searchQuery: query, isLoading: true);
    return _load();
  }

  Future<void> refresh() => _load();
}

final customersProvider =
    NotifierProvider<CustomersNotifier, CustomersState>(CustomersNotifier.new);
