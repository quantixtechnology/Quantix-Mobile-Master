import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

class SocketService {
  io.Socket? _socket;

  void connect(String token) {
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('connect', (_) {});
    _socket!.on('disconnect', (_) {});
    _socket!.on('connect_error', (_) {});

    _socket!.on('delivery:location_updated', _onLocationUpdated);
    _socket!.on('tracking:eta_updated', _onEtaUpdated);
    _socket!.on('order:status_changed', _onOrderStatusChanged);
    _socket!.on('notification:new', _onNewNotification);
  }

  void _onLocationUpdated(dynamic data) {}
  void _onEtaUpdated(dynamic data) {}
  void _onOrderStatusChanged(dynamic data) {}
  void _onNewNotification(dynamic data) {}

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});
