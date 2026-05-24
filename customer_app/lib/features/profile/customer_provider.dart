import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerState {
  final bool isLoading;
  final String? error;
  final String? name;
  final String? email;
  final String? phone;

  const CustomerState({
    this.isLoading = false,
    this.error,
    this.name,
    this.email,
    this.phone,
  });

  CustomerState copyWith({
    bool? isLoading,
    String? error,
    String? name,
    String? email,
    String? phone,
  }) =>
      CustomerState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}

class CustomerNotifier extends Notifier<CustomerState> {
  @override
  CustomerState build() => const CustomerState();
}

final customerProvider =
    NotifierProvider<CustomerNotifier, CustomerState>(CustomerNotifier.new);
