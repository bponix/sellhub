import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellhub/core/config/app_environment.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/navigation/deep_link_core.dart';
import 'package:sellhub/core/navigation/pending_product_deep_link.dart';
import 'package:sellhub/core/navigation/sellhub_shared_route_handler.dart';
import 'package:sellhub/core/navigation/unsupported_link_screen.dart';
import 'package:sellhub/core/services/analytics_service.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/route_names.dart';
import 'package:sellhub/injection_container.dart' as di;
import 'package:http/http.dart' as http;

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static Uri? _pendingUri;
  static final DeepLinkDuplicateGuard _duplicateGuard =
      DeepLinkDuplicateGuard();
  static const String _installHandoffFlag = 'installHandoff';
  static const String _installHandoffTokenKey = 'handoffToken';
  static const String _payloadTokenKey = 'payloadToken';
  static const String _installHandoffTimestamp = 'handoffTs';
  static const Duration _installHandoffWindow = Duration(hours: 6);
  static const String _handoffHost = 'reseller.store.bponi.com';
  static const String _eventHost = 'bponi.com';

  static final Set<String> _publicRouteNames = <String>{
    RouteNames.splash,
    RouteNames.login,
    RouteNames.register,
    RouteNames.forgotPassword,
    RouteNames.unsupportedLink,
  };

  static final Set<String> _deferredRouteNames = <String>{
    RouteNames.home,
    RouteNames.sellingList,
    RouteNames.saved,
    RouteNames.profile,
    RouteNames.search,
    RouteNames.notifications,
    RouteNames.orders,
    RouteNames.teamInvite,
    RouteNames.settings,
    RouteNames.collection,
  };

  static final Set<String> _allowedHttpHosts = AppEnvironment.appLinkHosts
      .map((host) => host.toLowerCase())
      .toSet();
  static final Set<String> _publicRawPaths = <String>{
    '/',
    '/${RouteNames.splash}',
    '/${RouteNames.login}',
    '/${RouteNames.register}',
    '/${RouteNames.forgotPassword}',
    '/${RouteNames.unsupportedLink}',
  };

  static final Set<String> _deferredRawPaths = <String>{
    '/${RouteNames.home}',
    '/${RouteNames.sellingList}',
    '/${RouteNames.saved}',
    '/cart',
    '/favourite',
    '/${RouteNames.profile}',
    '/${RouteNames.search}',
    '/${RouteNames.notifications}',
    '/${RouteNames.teamInvite}',
    '/${RouteNames.orders}',
    '/${RouteNames.settings}',
    '/${RouteNames.collection}',
  };

  static Future<void> initialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _recordEvent('initial_received', uri: initial);
        _handleUri(initial);
      } else {
        await _restoreInstallHandoffFromClipboard();
      }
    } catch (error, stackTrace) {
      debugPrint('Deep link init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error) {
        debugPrint('Deep link stream failed: $error');
      },
    );
  }

  static Future<bool> consumePendingLink() async {
    final pending = await LocalStorage.getString(
      LocalStorage.pendingDeepLinkKey,
    );
    if (pending == null || pending.isEmpty) return false;
    try {
      final uri =
          await _resolveSignedPayloadUri(Uri.parse(pending)) ??
          Uri.parse(pending);
      await PendingProductDeepLinkHandler.persistFromUri(uri);
      final routed = _routeUri(uri);
      if (routed) {
        _recordEvent('pending_resumed', uri: uri);
        await LocalStorage.remove(LocalStorage.pendingDeepLinkKey);
      } else {
        _recordEvent('pending_failed', uri: uri, reason: 'unsupported');
        await LocalStorage.remove(LocalStorage.pendingDeepLinkKey);
        _showUnsupportedLink();
      }
      return routed;
    } catch (_) {
      return false;
    }
  }

  static Uri? normalizeExternalUri(String raw) {
    return DeepLinkCore.normalizeExternalUri(
      raw,
      allowedSchemes: <String>{AppEnvironment.appLinkScheme},
      allowBareDomain: true,
    );
  }

  static bool canHandleUri(Uri uri) {
    if (uri.scheme == AppEnvironment.appLinkScheme) return true;
    if (_allowedHttpHosts.contains(uri.host.toLowerCase())) return true;
    final domain = uri.queryParameters['domain']?.trim();
    final siteId = int.tryParse(uri.queryParameters['siteId']?.trim() ?? '');
    return domain != null && domain.isNotEmpty && siteId != null && siteId > 0;
  }

  static Future<bool> routeIncomingUri(Uri uri) async {
    uri = await _resolveSignedPayloadUri(uri) ?? uri;
    final store = _extractStore(uri);
    final routeName =
        uri.queryParameters['routeName'] ?? uri.queryParameters['route'];
    final hasRoutePayload = routeName != null && routeName.trim().isNotEmpty;
    if (store == null && !hasRoutePayload && !canHandleUri(uri)) {
      _recordEvent('rejected', uri: uri, reason: 'cannot_handle');
      return false;
    }
    await _guardAndRoute(uri);
    return true;
  }

  static void _handleUri(Uri uri) {
    if (!_duplicateGuard.shouldHandle(uri)) return;
    if (AppRouter.navigatorKey.currentContext == null) {
      _pendingUri = uri;
      _schedulePendingRetry();
      return;
    }
    _guardAndRoute(uri);
  }

  static Future<void> _guardAndRoute(Uri uri) async {
    uri = await _resolveSignedPayloadUri(uri) ?? uri;
    await PendingProductDeepLinkHandler.persistFromUri(uri);
    final store = _extractStore(uri);
    final routeName =
        uri.queryParameters['routeName'] ?? uri.queryParameters['route'];
    if (store != null && routeName != null && routeName.trim().isNotEmpty) {
      await LocalStorage.saveString(
        LocalStorage.pendingDeepLinkKey,
        uri.toString(),
      );
    }
    if (store != null) {
      StoreRegistry.currentStore = store;
      await LocalStorage.saveActiveStore(store);
      await _logStoreActivation(store, source: 'deeplink');
      AppRouter.go('/${RouteNames.splash}');
      return;
    }
    final loggedIn = await LocalStorage.isLogin();
    final routeAccess = DeepLinkCore.routeAccess(
      routeName,
      publicRoutes: _publicRouteNames,
      deferredRoutes: _deferredRouteNames,
    );
    final pathAccess = DeepLinkCore.pathAccess(
      uri.path.isEmpty ? '/' : uri.path,
      publicPaths: _publicRawPaths,
      deferredPaths: _deferredRawPaths,
    );
    if (routeAccess == DeepLinkRouteAccess.reject &&
        pathAccess == DeepLinkRouteAccess.reject) {
      _recordEvent('unsupported', uri: uri, reason: 'rejected_by_policy');
      _showUnsupportedLink();
      return;
    }
    if (!loggedIn &&
        (routeAccess == DeepLinkRouteAccess.deferUntilLogin ||
            (routeAccess == DeepLinkRouteAccess.reject &&
                pathAccess == DeepLinkRouteAccess.deferUntilLogin))) {
      _recordEvent('deferred_auth', uri: uri);
      await LocalStorage.saveString(
        LocalStorage.pendingDeepLinkKey,
        uri.toString(),
      );
      AppRouter.goToLogin(AppRouter.navigatorKey.currentContext!);
      return;
    }
    final routed = _routeUri(uri);
    if (!routed) {
      _recordEvent('unsupported', uri: uri, reason: 'route_not_handled');
      _showUnsupportedLink();
    }
  }

  static bool _routeUri(Uri uri) {
    final store = _extractStore(uri);
    if (store != null) {
      StoreRegistry.currentStore = store;
      LocalStorage.saveActiveStore(store);
      _logStoreActivation(store, source: 'payload');
      AppRouter.go('/${RouteNames.splash}');
      return true;
    }
    if (_handleSchemeLink(uri)) return true;
    if (_handleHttpLink(uri)) return true;
    _recordEvent('rejected', uri: uri, reason: 'no_matching_handler');
    return false;
  }

  static bool _handleSchemeLink(Uri uri) {
    if (uri.scheme != AppEnvironment.appLinkScheme) return false;

    if (uri.host == 'open') {
      final routeName =
          uri.queryParameters['routeName'] ?? uri.queryParameters['route'];
      if (routeName == null || routeName.isEmpty) return false;
      return _routeFromPayload(routeName, _payloadParamsForUri(uri), uri: uri);
    }

    return _routeRawPath(
      uri.path.isEmpty ? '/' : uri.path,
      uri.queryParameters,
      uri: uri,
    );
  }

  static bool _handleHttpLink(Uri uri) {
    if (!_allowedHttpHosts.contains(uri.host.toLowerCase())) return false;
    final routeName =
        uri.queryParameters['routeName'] ?? uri.queryParameters['route'];
    if (uri.path.startsWith('/app') &&
        routeName != null &&
        routeName.isNotEmpty) {
      return _routeFromPayload(routeName, _payloadParamsForUri(uri), uri: uri);
    }
    return _routeRawPath(
      uri.path.isEmpty ? '/' : uri.path,
      uri.queryParameters,
      uri: uri,
    );
  }

  static ActiveStore? _extractStore(Uri uri) {
    final domain = uri.queryParameters['domain']?.trim();
    final siteId = int.tryParse(uri.queryParameters['siteId']?.trim() ?? '');
    if (domain == null || domain.isEmpty || siteId == null) return null;
    return ActiveStore(
      siteId: siteId,
      domain: domain,
      title: uri.queryParameters['title']?.trim(),
      logoUrl: uri.queryParameters['logo']?.trim(),
    );
  }

  static Future<void> _logStoreActivation(
    ActiveStore store, {
    required String source,
  }) async {
    if (!di.sl.isRegistered<AnalyticsService>()) return;
    await di.sl<AnalyticsService>().logStoreActivated(
      siteId: store.siteId,
      domain: store.domain,
      source: source,
    );
  }

  static bool _routeFromPayload(
    String routeName,
    Map<String, String>? params, {
    Uri? uri,
  }) {
    final context = AppRouter.navigatorKey.currentContext;
    if (DeepLinkCore.routeAccess(
          routeName,
          publicRoutes: _publicRouteNames,
          deferredRoutes: _deferredRouteNames,
        ) ==
        DeepLinkRouteAccess.reject) {
      _recordEvent(
        'rejected_route',
        uri: uri,
        routeName: routeName,
        reason: 'unknown_route',
      );
      return false;
    }
    if (context != null) {
      SellHubSharedRouteHandler.handleRoutePayload(
        context,
        routeName: routeName,
        routeParams: params,
      ).then((handled) {
        if (handled) {
          _recordEvent('routed', uri: uri, routeName: routeName);
          return;
        }
        if (!context.mounted) return;
        PendingProductDeepLinkHandler.handleRoutePayload(
          context,
          routeName: routeName,
          routeParams: params,
        ).then((productHandled) {
          if (!productHandled) {
            AppRouter.goNamed(routeName, queryParameters: params);
            _recordEvent('routed', uri: uri, routeName: routeName);
          }
        });
      });
      return true;
    }
    AppRouter.goNamed(routeName, queryParameters: params);
    _recordEvent('routed', uri: uri, routeName: routeName);
    return true;
  }

  static Map<String, String>? _payloadParamsForUri(Uri uri) {
    return DeepLinkCore.sanitizeQueryParams(
      DeepLinkCore.payloadParamsForUri(uri),
    );
  }

  static String _buildLocation(String path, Map<String, String> query) {
    if (query.isEmpty) return path;
    return Uri(path: path, queryParameters: query).toString();
  }

  static bool _routeRawPath(
    String path,
    Map<String, String> query, {
    Uri? uri,
  }) {
    final normalizedPath = path.trim().isEmpty ? '/' : path.trim();
    if (DeepLinkCore.pathAccess(
          normalizedPath,
          publicPaths: _publicRawPaths,
          deferredPaths: _deferredRawPaths,
        ) ==
        DeepLinkRouteAccess.reject) {
      _recordEvent('rejected_path', uri: uri, reason: normalizedPath);
      return false;
    }
    AppRouter.go(_buildLocation(normalizedPath, query));
    _recordEvent('routed', uri: uri, reason: 'path');
    return true;
  }

  static void _schedulePendingRetry() {
    if (_pendingUri == null) return;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      final uri = _pendingUri;
      if (uri == null || AppRouter.navigatorKey.currentContext == null) return;
      _pendingUri = null;
      _guardAndRoute(uri);
    });
  }

  static void _showUnsupportedLink() {
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const UnsupportedLinkScreen()),
    );
  }

  static void _recordEvent(
    String event, {
    Uri? uri,
    String? routeName,
    String? reason,
  }) {
    developer.log(
      'sellhub_deep_link',
      name: 'sellhub.deep_link',
      error: <String, Object?>{
        'event': event,
        'uri': uri?.toString(),
        'routeName': routeName,
        'reason': reason,
      },
    );
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl<AnalyticsService>().logDeepLinkEvent(
        event: event,
        uri: uri?.toString(),
        routeName: routeName,
        reason: reason,
      );
    }
    unawaited(
      _sendEvent(
        event: event,
        uri: uri?.toString(),
        routeName: routeName,
        reason: reason,
      ),
    );
  }

  static Future<void> _sendEvent({
    required String event,
    String? uri,
    String? routeName,
    String? reason,
  }) async {
    try {
      await http.post(
        Uri.https(_eventHost, '/d/events'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, Object?>{
          'app': 'sellhub',
          'event': event,
          'uri': uri,
          'routeName': routeName,
          'reason': reason,
        }),
      );
    } catch (_) {}
  }

  @visibleForTesting
  static ActiveStore? extractStoreForTesting(Uri uri) => _extractStore(uri);

  static Future<void> _restoreInstallHandoffFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final raw = data?.text?.trim();
      final uri =
          await _redeemSignedInstallHandoff(raw) ??
          _extractInstallHandoffUri(raw);
      if (uri == null) return;
      _recordEvent('install_handoff_detected', uri: uri);
      await Clipboard.setData(const ClipboardData(text: ''));
      _handleUri(uri);
    } catch (error, stackTrace) {
      developer.log(
        'Install handoff restore failed: $error',
        stackTrace: stackTrace,
        name: 'sellhub.deep_link',
      );
    }
  }

  static Uri? _extractInstallHandoffUri(String? raw) {
    return DeepLinkCore.extractInstallHandoffUri(
      raw,
      normalizeUri: normalizeExternalUri,
      canHandle: canHandleUri,
      flagKey: _installHandoffFlag,
      timestampKey: _installHandoffTimestamp,
      window: _installHandoffWindow,
    );
  }

  static Future<Uri?> _redeemSignedInstallHandoff(String? raw) async {
    if (raw == null || raw.isEmpty) return null;
    final handoffUri = Uri.tryParse(raw);
    if (handoffUri == null) return null;
    if (handoffUri.queryParameters[_installHandoffFlag] != '1') return null;
    final token = handoffUri.queryParameters[_installHandoffTokenKey];
    if (token == null || token.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.https(_handoffHost, '/app-handoff/redeem', <String, String>{
          'token': token,
        }),
      );
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map) return null;
      final deepLink = payload['deepLink'];
      if (deepLink is! String || deepLink.isEmpty) return null;
      final uri = normalizeExternalUri(deepLink);
      if (uri == null || !canHandleUri(uri)) return null;
      return uri;
    } catch (_) {
      return null;
    }
  }

  static Future<Uri?> _resolveSignedPayloadUri(Uri uri) async {
    if (uri.scheme == AppEnvironment.appLinkScheme) return null;
    if (!_allowedHttpHosts.contains(uri.host.toLowerCase())) return null;
    final token = uri.queryParameters[_payloadTokenKey];
    if (token == null || token.isEmpty) return null;
    try {
      final response = await http.get(
        Uri.https(_handoffHost, '/app-payload/redeem', <String, String>{
          'token': token,
        }),
      );
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map) return null;
      final deepLink = payload['deepLink'];
      if (deepLink is! String || deepLink.isEmpty) return null;
      final normalized = normalizeExternalUri(deepLink);
      if (normalized == null || !canHandleUri(normalized)) return null;
      return normalized;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static Map<String, String>? payloadParamsForTesting(Uri uri) =>
      _payloadParamsForUri(uri);

  @visibleForTesting
  static DeepLinkRouteAccess routeAccessForTesting(String? routeName) =>
      DeepLinkCore.routeAccess(
        routeName,
        publicRoutes: _publicRouteNames,
        deferredRoutes: _deferredRouteNames,
      );

  @visibleForTesting
  static DeepLinkRouteAccess pathAccessForTesting(String path) =>
      DeepLinkCore.pathAccess(
        path,
        publicPaths: _publicRawPaths,
        deferredPaths: _deferredRawPaths,
      );
}
