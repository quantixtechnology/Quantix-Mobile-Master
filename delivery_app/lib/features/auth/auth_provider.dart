import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeliveryAuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? riderId;

  const DeliveryAuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.riderId,
  });

  DeliveryAuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? riderId,
  }) =>
      DeliveryAuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        riderId: riderId ?? this.riderId,
      );
}

class DeliveryAuthNotifier extends Notifier<DeliveryAuthState> {
  @override
  DeliveryAuthState build() => const DeliveryAuthState();
}

final deliveryAuthProvider =
    NotifierProvider<DeliveryAuthNotifier, DeliveryAuthState>(
        DeliveryAuthNotifier.new);
