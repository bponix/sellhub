import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/notifications/app_notification.dart';

part 'notification_center_state.dart';

class NotificationCenterCubit extends SafeCubit<NotificationCenterState> {
  NotificationCenterCubit() : super(const NotificationCenterState());

  static const String _storageKey = 'store_notification_center_v1';
  static const int _maxNotifications = 50;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      emit(state.copyWith(isReady: true));
      return;
    }
    emit(
      state.copyWith(
        notifications: AppNotification.decodeList(raw),
        isReady: true,
      ),
    );
  }

  Future<void> push({
    required AppNotificationType type,
    required String title,
    required String message,
    String? category,
    String? routeName,
    Map<String, String>? routeParams,
  }) async {
    final notification = AppNotification(
      id: _generateId(),
      title: title,
      message: message,
      type: type,
      category: category,
      routeName: routeName,
      routeParams: routeParams,
    );
    final updated = <AppNotification>[
      notification,
      ...state.notifications,
    ].take(_maxNotifications).toList(growable: false);
    emit(state.copyWith(notifications: updated, isReady: true));
    await _persist(updated);
  }

  Future<void> markRead(String id) async {
    final updated = state.notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList(growable: false);
    emit(state.copyWith(notifications: updated));
    await _persist(updated);
  }

  Future<void> markAllRead() async {
    final updated = state.notifications
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    emit(state.copyWith(notifications: updated));
    await _persist(updated);
  }

  Future<void> remove(String id) async {
    final updated = state.notifications
        .where((item) => item.id != id)
        .toList(growable: false);
    emit(state.copyWith(notifications: updated));
    await _persist(updated);
  }

  Future<void> clearAll() async {
    emit(state.copyWith(notifications: const <AppNotification>[]));
    await _persist(const <AppNotification>[]);
  }

  Future<void> _persist(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, AppNotification.encodeList(items));
  }

  String _generateId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(1 << 32)}';
  }
}
