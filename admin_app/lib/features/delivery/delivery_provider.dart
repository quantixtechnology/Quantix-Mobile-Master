import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiderStatus {
  final String riderId;
  final String name;
  final bool isOnline;
  final String? currentOrderId;

  const RiderStatus({
    required this.riderId,
    required this.name,
    required this.isOnline,
    this.currentOrderId,
  });
}

class DeliveryManagementState {
  final bool isLoading;
  final List<RiderStatus> riders;
  final String? error;

  const DeliveryManagementState({
    this.isLoading = false,
    this.riders = const [],
    this.error,
  });

  DeliveryManagementState copyWith({
    bool? isLoading,
    List<RiderStatus>? riders,
    String? error,
  }) =>
      DeliveryManagementState(
        isLoading: isLoading ?? this.isLoading,
        riders: riders ?? this.riders,
        error: error,
      );
}

class DeliveryManagementNotifier extends Notifier<DeliveryManagementState> {
  @override
  DeliveryManagementState build() => const DeliveryManagementState();
}

final deliveryManagementProvider =
    NotifierProvider<DeliveryManagementNotifier, DeliveryManagementState>(
        DeliveryManagementNotifier.new);
