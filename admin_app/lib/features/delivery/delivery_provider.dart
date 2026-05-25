import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class RiderStatus {
  final String riderId;
  final String name;
  final bool isActive;
  final String? activeOrderId;

  const RiderStatus({
    required this.riderId,
    required this.name,
    required this.isActive,
    this.activeOrderId,
  });

  factory RiderStatus.fromJson(Map<String, dynamic> json) {
    final rider = json['rider'] as Map<String, dynamic>? ?? json;
    final activeOrder = json['activeOrder'] as Map<String, dynamic>?;
    return RiderStatus(
      riderId: rider['id'] as String? ?? '',
      name: rider['name'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      activeOrderId: activeOrder?['id'] as String?,
    );
  }
}

class DeliveryManagementState {
  final List<RiderStatus> riders;
  final bool isLoading;
  final String? error;

  const DeliveryManagementState({
    this.riders = const [],
    this.isLoading = false,
    this.error,
  });

  DeliveryManagementState copyWith({
    List<RiderStatus>? riders,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      DeliveryManagementState(
        riders: riders ?? this.riders,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class DeliveryManagementNotifier extends Notifier<DeliveryManagementState> {
  @override
  DeliveryManagementState build() {
    _load();
    return const DeliveryManagementState(isLoading: true);
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).dio.get('/admin/riders');
      final list = res.data as List<dynamic>;
      final riders = list
          .map((e) => RiderStatus.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(riders: riders, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _load();
}

final deliveryManagementProvider =
    NotifierProvider<DeliveryManagementNotifier, DeliveryManagementState>(
        DeliveryManagementNotifier.new);
