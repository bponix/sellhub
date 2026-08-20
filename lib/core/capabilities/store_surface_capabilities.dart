import 'package:equatable/equatable.dart';

class StoreSurfaceCapability extends Equatable {
  const StoreSurfaceCapability({
    required this.key,
    required this.state,
    this.reason,
    this.source,
  });

  final String key;
  final String state;
  final String? reason;
  final String? source;

  bool get isEnabled => state == 'enabled' || state == 'trial';

  factory StoreSurfaceCapability.fromJson(Map<String, dynamic> json) {
    return StoreSurfaceCapability(
      key: json['key'] as String? ?? '',
      state: json['state'] as String? ?? 'disabled',
      reason: json['reason'] as String?,
      source: json['source'] as String?,
    );
  }

  @override
  List<Object?> get props => <Object?>[key, state, reason, source];
}

class StoreSurfaceWarning extends Equatable {
  const StoreSurfaceWarning({
    required this.code,
    required this.message,
    required this.severity,
  });

  final String code;
  final String message;
  final String severity;

  factory StoreSurfaceWarning.fromJson(Map<String, dynamic> json) {
    return StoreSurfaceWarning(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
    );
  }

  @override
  List<Object?> get props => <Object?>[code, message, severity];
}

class StoreSurfaceCapabilitySet extends Equatable {
  const StoreSurfaceCapabilitySet({
    required this.siteId,
    required this.appType,
    required this.surfaceKey,
    required this.capabilities,
    this.warnings = const <StoreSurfaceWarning>[],
  });

  final int siteId;
  final String appType;
  final String surfaceKey;
  final Map<String, StoreSurfaceCapability> capabilities;
  final List<StoreSurfaceWarning> warnings;

  bool isEnabled(String key) => capabilities[key]?.isEnabled ?? false;

  StoreSurfaceCapability? firstUnavailable(Iterable<String> keys) {
    for (final key in keys) {
      final capability = capabilities[key];
      if (capability == null || !capability.isEnabled) {
        return capability ?? StoreSurfaceCapability(key: key, state: 'missing');
      }
    }
    return null;
  }

  factory StoreSurfaceCapabilitySet.fromJson(Map<String, dynamic> json) {
    final capabilityRows =
        json['capabilities'] as List<dynamic>? ?? const <dynamic>[];
    final capabilities = <String, StoreSurfaceCapability>{};
    for (final row in capabilityRows) {
      if (row is! Map<String, dynamic>) continue;
      final capability = StoreSurfaceCapability.fromJson(row);
      if (capability.key.isNotEmpty) {
        capabilities[capability.key] = capability;
      }
    }

    return StoreSurfaceCapabilitySet(
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      appType: json['appType'] as String? ?? 'store',
      surfaceKey: json['surfaceKey'] as String? ?? '',
      capabilities: capabilities,
      warnings: (json['warnings'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(StoreSurfaceWarning.fromJson)
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    siteId,
    appType,
    surfaceKey,
    capabilities,
    warnings,
  ];
}
