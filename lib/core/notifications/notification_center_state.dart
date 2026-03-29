part of 'notification_center_cubit.dart';

class NotificationCenterState extends Equatable {
  const NotificationCenterState({
    this.notifications = const <AppNotification>[],
    this.isReady = false,
  });

  final List<AppNotification> notifications;
  final bool isReady;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  NotificationCenterState copyWith({
    List<AppNotification>? notifications,
    bool? isReady,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      isReady: isReady ?? this.isReady,
    );
  }

  @override
  List<Object?> get props => <Object?>[notifications, isReady];
}
