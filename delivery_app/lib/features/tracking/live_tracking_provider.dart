import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantix_shared/quantix_shared.dart';

class LiveLocation {
  final double latitude;
  final double longitude;

  const LiveLocation({required this.latitude, required this.longitude});
}

class LiveTrackingState {
  final LiveLocation? currentLocation;
  final bool isBroadcasting;
  final String? activeOrderId;
  final String? error;

  const LiveTrackingState({
    this.currentLocation,
    this.isBroadcasting = false,
    this.activeOrderId,
    this.error,
  });

  LiveTrackingState copyWith({
    LiveLocation? currentLocation,
    bool? isBroadcasting,
    String? activeOrderId,
    String? error,
    bool clearError = false,
  }) =>
      LiveTrackingState(
        currentLocation: currentLocation ?? this.currentLocation,
        isBroadcasting: isBroadcasting ?? this.isBroadcasting,
        activeOrderId: activeOrderId ?? this.activeOrderId,
        error: clearError ? null : (error ?? this.error),
      );
}

class LiveTrackingNotifier extends Notifier<LiveTrackingState> {
  DeliveryRepository get _repo => ref.read(deliveryRepositoryProvider);

  @override
  LiveTrackingState build() => const LiveTrackingState();

  void startBroadcasting(String orderId) {
    state = state.copyWith(isBroadcasting: true, activeOrderId: orderId);
  }

  void stopBroadcasting() {
    state = state.copyWith(isBroadcasting: false);
  }

  Future<void> updateLocation(double lat, double lng, {double? heading}) async {
    state = state.copyWith(
      currentLocation: LiveLocation(latitude: lat, longitude: lng),
    );
    final orderId = state.activeOrderId;
    if (state.isBroadcasting && orderId != null) {
      try {
        await _repo.broadcastLocation(orderId, lat: lat, lng: lng, heading: heading);
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    }
  }
}

final liveTrackingProvider =
    NotifierProvider<LiveTrackingNotifier, LiveTrackingState>(
        LiveTrackingNotifier.new);
