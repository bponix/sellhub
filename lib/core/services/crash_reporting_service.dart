import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  CrashReportingService(this._crashlytics);

  final FirebaseCrashlytics? _crashlytics;

  void registerGlobalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(recordError(error, stackTrace, fatal: true));
      return true;
    };
  }

  Future<void> setUser(String? id) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics.setUserIdentifier(id ?? '');
    } catch (error, stackTrace) {
      debugPrint('Crash user set failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics.recordFlutterFatalError(details);
    } catch (error, stackTrace) {
      debugPrint('Crashlytics flutter error failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    if (_crashlytics == null) return;
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (innerError, innerStack) {
      debugPrint('Crashlytics record error failed: $innerError');
      debugPrintStack(stackTrace: innerStack);
    }
  }
}
