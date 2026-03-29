import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  LocalNotificationService._internal();

  static final LocalNotificationService instance =
      LocalNotificationService._internal();

  static const String _channelId = 'store_general_notifications';
  static const String _channelName = 'Store notifications';
  static const String _pendingPayloadKey = 'store_pending_notification_payload';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        await _savePendingPayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'General SellHub notifications',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await initialize();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'General SellHub notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      details,
      payload: payload == null ? null : jsonEncode(payload),
    );
  }

  Future<String?> consumePendingPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(_pendingPayloadKey);
    if (payload != null) {
      await prefs.remove(_pendingPayloadKey);
    }
    return payload;
  }

  Future<void> _savePendingPayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPayloadKey, payload);
  }
}

@pragma('vm:entry-point')
Future<void> _notificationTapBackground(NotificationResponse response) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('store_pending_notification_payload', payload);
}
