import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  RemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig? _remoteConfig;

  Future<void> initialize() async {
    if (_remoteConfig == null) return;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await _remoteConfig.setDefaults(const <String, dynamic>{
        'sellhub_force_store_selector': false,
        'sellhub_show_nearby_stores': true,
        'sellhub_discovery_radius_km': 15,
      });
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      debugPrint('Remote config init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  bool getBool(String key) => _remoteConfig?.getBool(key) ?? false;

  int getInt(String key) => _remoteConfig?.getInt(key) ?? 0;
}
