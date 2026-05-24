import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveLocation {
  final double latitude;
  final double longitude;

  const LiveLocation({required this.latitude, required this.longitude});
}

class LiveTrackingState {
  final LiveLocation? currentLocation;
  final bool isBroadcasting;

  const LiveTrackingState({
    this.currentLocation,
    this.isBroadcasting = false,
  });

  LiveTrackingState copyWith({
    LiveLocation? currentLocation,
    bool? isBroadcasting,
  }) =>
      LiveTrackingState(
        currentLocation: currentLocation ?? this.currentLocation,
        isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      );
}

class LiveTrackingNotifier extends Notifier<LiveTrackingState> {
  @override
  LiveTrackingState build() => const LiveTrackingState();

  void updateLocation(double lat, double lng) {
    state = state.copyWith(
      currentLocation: LiveLocation(latitude: lat, longitude: lng),
    );
  }

  void startBroadcasting() => state = state.copyWith(isBroadcasting: true);
  void stopBroadcasting() => state = state.copyWith(isBroadcasting: false);
}

final liveTrackingProvider =
    NotifierProvider<LiveTrackingNotifier, LiveTrackingState>(
        LiveTrackingNotifier.new);
