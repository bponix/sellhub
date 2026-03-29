import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics? _analytics;

  FirebaseAnalyticsObserver? get observer => _analytics == null
      ? null
      : FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logAppOpen() async {
    if (_analytics == null) return;
    try {
      await _analytics.logAppOpen();
    } catch (error, stackTrace) {
      debugPrint('Analytics app open failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> logStoreActivated({
    required int siteId,
    required String domain,
    required String source,
  }) async {
    await _logEvent('store_activated', <String, Object>{
      'site_id': siteId,
      'domain': domain,
      'source': source,
    });
  }

  Future<void> logSearch({required String query, required int siteId}) async {
    await _logEvent('store_search', <String, Object>{
      'query': query,
      'site_id': siteId,
    });
  }

  Future<void> logCheckoutStarted({
    required int siteId,
    required bool fromCart,
    required int totalItems,
  }) async {
    await _logEvent('checkout_started', <String, Object>{
      'site_id': siteId,
      'from_cart': fromCart,
      'total_items': totalItems,
    });
  }

  Future<void> logDeepLinkEvent({
    required String event,
    String? uri,
    String? routeName,
    String? reason,
  }) async {
    final parameters = <String, Object>{
      'event': event,
      if (uri != null && uri.isNotEmpty) 'uri': uri,
      if (routeName != null && routeName.isNotEmpty) 'route_name': routeName,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };
    await _logEvent('deep_link_event', parameters);
  }

  Future<void> _logEvent(String name, Map<String, Object> parameters) async {
    if (_analytics == null) return;
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error, stackTrace) {
      debugPrint('Analytics event $name failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
