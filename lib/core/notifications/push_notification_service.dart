import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/navigation/pending_product_deep_link.dart';
import 'package:sellhub/core/notifications/app_notification.dart';
import 'package:sellhub/core/notifications/local_notification_service.dart';
import 'package:sellhub/core/notifications/notification_center_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/route_names.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static NotificationCenterCubit? _notificationCenterCubit;
  static bool _initialized = false;
  static const String _topicSnapshotKey = 'store_push_topic_snapshot_v1';
  static const String _pendingRoutePayloadKey =
      'store_pending_push_route_payload_v1';

  static Future<void> initialize({
    required NotificationCenterCubit notificationCenterCubit,
  }) async {
    if (_initialized) return;
    final messaging = _messaging;
    if (messaging == null) return;
    _notificationCenterCubit = notificationCenterCubit;

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteOpen);
      messaging.onTokenRefresh.listen((_) {
        unawaited(syncSubscriptions());
      });
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleRemoteOpen(initialMessage);
      }
      await _consumePendingRoutePayload();
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Push notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> syncSubscriptions() async {
    final messaging = _messaging;
    if (messaging == null) return;
    try {
      final isLoggedIn = await LocalStorage.isLogin();
      if (!isLoggedIn) {
        await unsubscribeAll();
        return;
      }

      final userId = await LocalStorage.getUserID();
      final customerId = await LocalStorage.getCustomerID();
      final topics = <String>{};
      if (userId != null && userId > 0) {
        topics.add('store_user_$userId');
      }
      if (customerId != null && customerId > 0) {
        topics.add('store_customer_$customerId');
      }

      final previousTopics = await LocalStorage.getStringList(
        _topicSnapshotKey,
      );
      final previousSet = previousTopics.toSet();
      final toUnsubscribe = previousSet.difference(topics);
      final toSubscribe = topics.difference(previousSet);

      for (final topic in toUnsubscribe) {
        await messaging.unsubscribeFromTopic(topic);
      }
      for (final topic in toSubscribe) {
        await messaging.subscribeToTopic(topic);
      }
      await LocalStorage.saveStringList(
        _topicSnapshotKey,
        topics.toList(growable: false),
      );
    } catch (error, stackTrace) {
      debugPrint('Push subscription sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> unsubscribeAll() async {
    final messaging = _messaging;
    if (messaging == null) {
      await LocalStorage.remove(_topicSnapshotKey);
      return;
    }
    try {
      final topics = await LocalStorage.getStringList(_topicSnapshotKey);
      for (final topic in topics) {
        await messaging.unsubscribeFromTopic(topic);
      }
      await LocalStorage.remove(_topicSnapshotKey);
    } catch (error, stackTrace) {
      debugPrint('Push unsubscribe failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> handleLocalNotificationPayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final routeName = decoded['routeName']?.toString();
      final routeParams = _extractRouteParams(decoded['routeParams']);
      if (routeName == null || routeName.isEmpty) return;
      if (AppRouter.navigatorKey.currentContext != null) {
        final handled = await PendingProductDeepLinkHandler.handleRoutePayload(
          AppRouter.navigatorKey.currentContext!,
          routeName: routeName,
          routeParams: routeParams,
        );
        if (handled) {
          return;
        }
      }
      AppRouter.goNamed(routeName, queryParameters: routeParams);
    } catch (error, stackTrace) {
      debugPrint('Local notification payload handling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title?.trim();
    final body = message.notification?.body?.trim();
    final routeName = message.data['routeName']?.toString();
    final category = message.data['category']?.toString();
    final routeParams = _extractRouteParams(message.data['routeParams']);

    if (title != null && title.isNotEmpty && body != null && body.isNotEmpty) {
      await _notificationCenterCubit?.push(
        type: AppNotificationType.info,
        title: title,
        message: body,
        category: category,
        routeName: routeName,
        routeParams: routeParams,
      );
      await LocalNotificationService.instance.show(
        title: title,
        body: body,
        payload: <String, String>{
          'routeName': routeName ?? RouteNames.home,
          if (routeParams != null) 'routeParams': jsonEncode(routeParams),
        },
      );
    }
  }

  static Future<void> _handleRemoteOpen(RemoteMessage message) async {
    final routeName = message.data['routeName']?.toString();
    final routeParams = _extractRouteParams(message.data['routeParams']);
    if (routeName == null || routeName.isEmpty) return;

    if (AppRouter.navigatorKey.currentContext == null) {
      await LocalStorage.saveString(
        _pendingRoutePayloadKey,
        jsonEncode(<String, dynamic>{
          'routeName': routeName,
          'routeParams': routeParams,
        }),
      );
      return;
    }

    final context = AppRouter.navigatorKey.currentContext;
    if (context != null &&
        await PendingProductDeepLinkHandler.handleRoutePayload(
          context,
          routeName: routeName,
          routeParams: routeParams,
        )) {
      return;
    }
    AppRouter.goNamed(routeName, queryParameters: routeParams);
  }

  static Future<void> _consumePendingRoutePayload() async {
    final raw = await LocalStorage.getString(_pendingRoutePayloadKey);
    if (raw == null ||
        raw.isEmpty ||
        AppRouter.navigatorKey.currentContext == null) {
      return;
    }
    await LocalStorage.remove(_pendingRoutePayloadKey);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final routeName = decoded['routeName']?.toString();
      final routeParams = (decoded['routeParams'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
      if (routeName == null || routeName.isEmpty) return;
      if (AppRouter.navigatorKey.currentContext != null) {
        final handled = await PendingProductDeepLinkHandler.handleRoutePayload(
          AppRouter.navigatorKey.currentContext!,
          routeName: routeName,
          routeParams: routeParams,
        );
        if (handled) {
          return;
        }
      }
      AppRouter.goNamed(routeName, queryParameters: routeParams);
    } catch (_) {}
  }

  static Map<String, String>? _extractRouteParams(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      } catch (_) {}
      if (raw.contains('=')) {
        return Uri.splitQueryString(raw);
      }
    }
    return null;
  }

  static FirebaseMessaging? get _messaging {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    return FirebaseMessaging.instance;
  }
}
