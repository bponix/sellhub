import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart' as play_update;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sellhub/core/config/app_environment.dart';

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.available,
    required this.required,
    this.storeUrl,
    this.storeVersion,
    this.currentVersion,
    this.useImmediate = false,
    this.storeName,
    this.message,
  });

  final bool available;
  final bool required;
  final String? storeUrl;
  final String? storeVersion;
  final String? currentVersion;
  final bool useImmediate;
  final String? storeName;
  final String? message;
}

class AppUpdateChecker {
  static const Duration _cacheDuration = Duration(minutes: 30);
  static const String _cacheAtKey = 'store_app_update_cache_at';
  static const String _cachePayloadKey = 'store_app_update_cache_payload';

  Future<AppUpdateCheckResult?> check({bool force = false}) async {
    if (kIsWeb) return null;

    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = prefs.getInt(_cacheAtKey);
    final cachedPayload = prefs.getString(_cachePayloadKey);

    if (!force &&
        lastMs != null &&
        cachedPayload != null &&
        nowMs - lastMs < _cacheDuration.inMilliseconds) {
      return _decodeResult(cachedPayload);
    }

    AppUpdateCheckResult? info;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      info = await _checkPolicyEndpoint(packageInfo);

      if (Platform.isAndroid) {
        try {
          final update = await play_update.InAppUpdate.checkForUpdate();
          final available =
              update.updateAvailability ==
              play_update.UpdateAvailability.updateAvailable;
          final immediate =
              available &&
              update.immediateUpdateAllowed &&
              _isHighPriority(update.updatePriority);
          final playStoreUrl =
              'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
          info = AppUpdateCheckResult(
            available: (info?.available ?? false) || available,
            required: info?.required ?? available,
            storeUrl: info?.storeUrl ?? playStoreUrl,
            storeVersion: info?.storeVersion,
            currentVersion: info?.currentVersion ?? packageInfo.version,
            useImmediate: immediate && (info?.required ?? available),
            storeName: info?.storeName ?? 'Google Play',
            message: info?.message,
          );
        } on PlatformException catch (error, stackTrace) {
          developer.log(
            'Play update check failed: $error',
            stackTrace: stackTrace,
            name: 'store.app_update',
          );
        }
      } else if (Platform.isIOS) {
        info = info ?? await _checkIosStore(packageInfo);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Store update check failed: $error',
        stackTrace: stackTrace,
        name: 'store.app_update',
      );
    }

    info ??= const AppUpdateCheckResult(available: false, required: false);
    await prefs.setInt(_cacheAtKey, nowMs);
    await prefs.setString(_cachePayloadKey, _encodeResult(info));
    return info;
  }

  bool _isHighPriority(int? priority) => (priority ?? 0) >= 4;

  Future<AppUpdateCheckResult?> _checkPolicyEndpoint(
    PackageInfo packageInfo,
  ) async {
    final platform = Platform.isIOS
        ? 'ios'
        : (Platform.isAndroid ? 'android' : 'all');
    final response = await http.post(
      Uri.parse(AppEnvironment.apiBaseUrl),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'query': '''
          query HomeVersionPolicy(\$app: String!, \$platform: String!, \$version: String) {
            homeVersionPolicy(app: \$app, platform: \$platform, version: \$version) {
              latestVersion
              minSupportedVersion
              forceUpdate
              updateAvailable
              updateRequired
              storeUrl
              storeName
              message
            }
          }
        ''',
        'variables': <String, dynamic>{
          'app': AppEnvironment.appUpdateAppKey,
          'platform': platform,
          'version': packageInfo.version,
        },
      }),
    );
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final payload = Map<String, dynamic>.from(decoded);
    if (payload['errors'] is List && (payload['errors'] as List).isNotEmpty) {
      return null;
    }
    final data = _asStringMap(payload['data']);
    final policy = _asStringMap(data?['homeVersionPolicy']);
    if (policy == null) return null;
    return AppUpdateCheckResult(
      available: policy['updateAvailable'] as bool? ?? false,
      required: policy['updateRequired'] as bool? ?? false,
      storeUrl: policy['storeUrl'] as String?,
      storeVersion: policy['latestVersion'] as String?,
      currentVersion: packageInfo.version,
      useImmediate:
          (policy['updateRequired'] as bool? ?? false) && Platform.isAndroid,
      storeName: policy['storeName'] as String?,
      message: policy['message'] as String?,
    );
  }

  Future<AppUpdateCheckResult> _checkIosStore(PackageInfo packageInfo) async {
    final response = await http.get(
      Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=${packageInfo.packageName}',
      ),
    );
    if (response.statusCode != 200) {
      return AppUpdateCheckResult(
        available: false,
        required: false,
        currentVersion: packageInfo.version,
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = payload['results'];
    if (results is! List || results.isEmpty) {
      return AppUpdateCheckResult(
        available: false,
        required: false,
        currentVersion: packageInfo.version,
      );
    }
    final first = results.first as Map<String, dynamic>;
    final storeVersion = first['version']?.toString();
    final storeUrl = first['trackViewUrl']?.toString();
    return AppUpdateCheckResult(
      available: storeVersion != null && storeVersion != packageInfo.version,
      required: false,
      storeUrl: storeUrl,
      storeVersion: storeVersion,
      currentVersion: packageInfo.version,
      storeName: 'App Store',
    );
  }

  String _encodeResult(AppUpdateCheckResult result) {
    return jsonEncode(<String, dynamic>{
      'available': result.available,
      'required': result.required,
      'storeUrl': result.storeUrl,
      'storeVersion': result.storeVersion,
      'currentVersion': result.currentVersion,
      'useImmediate': result.useImmediate,
      'storeName': result.storeName,
      'message': result.message,
    });
  }

  AppUpdateCheckResult _decodeResult(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const AppUpdateCheckResult(available: false, required: false);
    }
    final payload = Map<String, dynamic>.from(decoded);
    return AppUpdateCheckResult(
      available: payload['available'] as bool? ?? false,
      required: payload['required'] as bool? ?? false,
      storeUrl: payload['storeUrl'] as String?,
      storeVersion: payload['storeVersion'] as String?,
      currentVersion: payload['currentVersion'] as String?,
      useImmediate: payload['useImmediate'] as bool? ?? false,
      storeName: payload['storeName'] as String?,
      message: payload['message'] as String?,
    );
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return value.map(
      (dynamic key, dynamic entryValue) =>
          MapEntry(key.toString(), entryValue),
    );
  }
}
