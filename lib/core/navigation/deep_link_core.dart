import 'dart:convert';

enum DeepLinkRouteAccess { public, deferUntilLogin, reject }

class DeepLinkDuplicateGuard {
  String? _lastHandled;
  DateTime? _lastHandledAt;

  bool shouldHandle(Uri uri, {Duration window = const Duration(seconds: 2)}) {
    final now = DateTime.now();
    final key = uri.toString();
    if (_lastHandled == key &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!).abs() < window) {
      return false;
    }
    _lastHandled = key;
    _lastHandledAt = now;
    return true;
  }
}

class DeepLinkPendingStore {
  const DeepLinkPendingStore({
    required this.save,
    required this.load,
    required this.clear,
  });

  final Future<void> Function(String value) save;
  final Future<String?> Function() load;
  final Future<void> Function() clear;

  Future<void> persistUri(Uri uri) => save(uri.toString());

  Future<Uri?> loadUri() async {
    final raw = await load();
    if (raw == null || raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }
}

class DeepLinkCore {
  static const Set<String> defaultReservedKeys = <String>{
    'routeName',
    'route',
    'params',
    'query',
  };

  static Uri? normalizeExternalUri(
    String raw, {
    Set<String> allowedSchemes = const <String>{},
    bool allowBareDomain = false,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final decoded = _decodeCandidate(trimmed);
    final direct = Uri.tryParse(decoded);
    if (direct != null && (direct.hasScheme || direct.host.isNotEmpty)) {
      final scheme = direct.scheme.toLowerCase();
      if (scheme.isEmpty) return direct;
      if (scheme == 'http' || scheme == 'https') return direct;
      if (allowedSchemes.contains(scheme)) return direct;
      return null;
    }
    if (allowBareDomain && !decoded.contains('://') && decoded.contains('.')) {
      return Uri.tryParse('https://${decoded.toLowerCase()}');
    }
    return null;
  }

  static Map<String, String>? payloadParamsForUri(
    Uri uri, {
    Set<String> reservedKeys = defaultReservedKeys,
  }) {
    final params = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (key.isEmpty || value.isEmpty || reservedKeys.contains(key)) {
        continue;
      }
      params[key] = value;
    }
    final nested =
        parseQueryParams(
          uri.queryParameters['params'] ?? uri.queryParameters['query'],
        ) ??
        const <String, String>{};
    if (nested.isNotEmpty) {
      params.addAll(nested);
    }
    return params.isEmpty ? null : params;
  }

  static Map<String, String>? parseQueryParams(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
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
    return null;
  }

  static Map<String, String>? sanitizeQueryParams(
    Map<String, String>? input, {
    int maxKeyLength = 64,
    int maxValueLength = 512,
  }) {
    if (input == null || input.isEmpty) return input;
    final output = <String, String>{};
    for (final entry in input.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (key.isEmpty || key.length > maxKeyLength) continue;
      if (value.length > maxValueLength) continue;
      output[key] = value;
    }
    return output;
  }

  static DeepLinkRouteAccess routeAccess(
    String? routeName, {
    required Set<String> publicRoutes,
    required Set<String> deferredRoutes,
  }) {
    if (routeName == null || routeName.trim().isEmpty) {
      return DeepLinkRouteAccess.reject;
    }
    if (publicRoutes.contains(routeName)) return DeepLinkRouteAccess.public;
    if (deferredRoutes.contains(routeName)) {
      return DeepLinkRouteAccess.deferUntilLogin;
    }
    return DeepLinkRouteAccess.reject;
  }

  static DeepLinkRouteAccess pathAccess(
    String path, {
    Set<String> publicPaths = const <String>{},
    Set<String> publicPrefixes = const <String>{},
    Set<String> deferredPaths = const <String>{},
    Set<String> deferredPrefixes = const <String>{},
  }) {
    final normalized = path.trim().isEmpty ? '/' : path.trim();
    if (publicPaths.contains(normalized) ||
        _matchesPrefix(normalized, publicPrefixes)) {
      return DeepLinkRouteAccess.public;
    }
    if (deferredPaths.contains(normalized) ||
        _matchesPrefix(normalized, deferredPrefixes)) {
      return DeepLinkRouteAccess.deferUntilLogin;
    }
    return DeepLinkRouteAccess.reject;
  }

  static Uri? extractInstallHandoffUri(
    String? raw, {
    required Uri? Function(String raw) normalizeUri,
    required bool Function(Uri uri) canHandle,
    String flagKey = 'installHandoff',
    String timestampKey = 'handoffTs',
    Duration window = const Duration(hours: 6),
  }) {
    if (raw == null || raw.isEmpty) return null;
    final uri = normalizeUri(raw);
    if (uri == null || !canHandle(uri)) return null;
    if (uri.queryParameters[flagKey] != '1') return null;
    final timestampMs = int.tryParse(uri.queryParameters[timestampKey] ?? '');
    if (timestampMs == null) return null;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    if (DateTime.now().difference(timestamp).abs() > window) return null;
    return uri;
  }

  static String _decodeCandidate(String value) {
    if (!value.contains('%')) return value;
    try {
      return Uri.decodeFull(value);
    } catch (_) {
      return value;
    }
  }

  static bool _matchesPrefix(String path, Set<String> prefixes) {
    for (final prefix in prefixes) {
      if (path == prefix || (prefix != '/' && path.startsWith('$prefix/'))) {
        return true;
      }
    }
    return false;
  }
}
