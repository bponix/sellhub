import 'dart:convert';

import 'package:flutter/foundation.dart';

enum AppNotificationType { info, success, warning, danger }

@immutable
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.category,
    this.routeName,
    this.routeParams,
    DateTime? timestamp,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final String? category;
  final String? routeName;
  final Map<String, String>? routeParams;
  final DateTime timestamp;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    AppNotificationType? type,
    String? category,
    String? routeName,
    Map<String, String>? routeParams,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      routeName: routeName ?? this.routeName,
      routeParams: routeParams ?? this.routeParams,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'category': category,
      'routeName': routeName,
      'routeParams': routeParams,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => AppNotificationType.info,
      ),
      category: json['category'] as String?,
      routeName: json['routeName'] as String?,
      routeParams: (json['routeParams'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  static String encodeList(List<AppNotification> items) {
    return jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );
  }

  static List<AppNotification> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <AppNotification>[];
    return decoded
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }
}
