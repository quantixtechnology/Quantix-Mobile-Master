import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
  });
}

class NotificationState {
  final bool isLoading;
  final List<AppNotification> notifications;
  final String? error;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    bool? isLoading,
    List<AppNotification>? notifications,
    String? error,
  }) =>
      NotificationState(
        isLoading: isLoading ?? this.isLoading,
        notifications: notifications ?? this.notifications,
        error: error,
      );
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  void addNotification(AppNotification notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);
