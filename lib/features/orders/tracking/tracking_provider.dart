import 'package:flutter_riverpod/flutter_riverpod.dart';

class TrackingLocation {
  final double latitude;
  final double longitude;

  const TrackingLocation({required this.latitude, required this.longitude});
}

class TrackingState {
  final bool isLoading;
  final String? error;
  final TrackingLocation? driverLocation;
  final String? eta;
  final String? orderStatus;

  const TrackingState({
    this.isLoading = false,
    this.error,
    this.driverLocation,
    this.eta,
    this.orderStatus,
  });

  TrackingState copyWith({
    bool? isLoading,
    String? error,
    TrackingLocation? driverLocation,
    String? eta,
    String? orderStatus,
  }) =>
      TrackingState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        driverLocation: driverLocation ?? this.driverLocation,
        eta: eta ?? this.eta,
        orderStatus: orderStatus ?? this.orderStatus,
      );
}

class TrackingNotifier extends Notifier<TrackingState> {
  @override
  TrackingState build() => const TrackingState();

  void onLocationUpdated(double lat, double lng) {
    state = state.copyWith(
      driverLocation: TrackingLocation(latitude: lat, longitude: lng),
    );
  }

  void onEtaUpdated(String eta) {
    state = state.copyWith(eta: eta);
  }

  void onOrderStatusChanged(String status) {
    state = state.copyWith(orderStatus: status);
  }
}

final trackingProvider =
    NotifierProvider<TrackingNotifier, TrackingState>(TrackingNotifier.new);
