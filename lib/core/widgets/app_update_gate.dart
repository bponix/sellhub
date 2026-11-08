import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Keeps every Bponi app on its latest store version. The same file lives in each app.
///
/// Android: Google Play's in-app update. When Play has a newer version, its full-screen update
/// runs at once (download, install, restart). If the person backs out of it, or the app did not
/// come from Play, a ribbon stays at the top until they update.
///
/// iOS: Apple does not let an app update itself, so the App Store is asked for the latest
/// version; when it is newer, the ribbon stays at the top and opens the store.
///
/// The ribbon cannot be dismissed. It sits above the app (pushing it down, never covering it)
/// and is checked again whenever the app comes back to the front.
///
/// Wrap the app in MaterialApp's `builder`: `builder: (context, child) => AppUpdateGate(child: child!)`.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

/// A newer version in the store, and where to get it.
class _StoreUpdate {
  const _StoreUpdate(this.url, {this.playImmediate = false});

  final String url;

  /// Google Play can run its full-screen update (the button retries it).
  final bool playImmediate;
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  _StoreUpdate? _update;
  var _checking = false;
  var _offeredImmediate = false;
  DateTime? _checkedAt;

  /// QA only (debug builds): pretend the store has this version, e.g.
  /// `--dart-define=APP_UPDATE_STORE_VERSION=99.0.0`.
  static const _debugStoreVersion = String.fromEnvironment(
    'APP_UPDATE_STORE_VERSION',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Back from the store (or anywhere): look again, at most every few minutes.
    final last = _checkedAt;
    if (last == null ||
        DateTime.now().difference(last) > const Duration(minutes: 3)) {
      unawaited(_check());
    }
  }

  Future<void> _check() async {
    if (kIsWeb || _checking) return;
    _checking = true;
    _checkedAt = DateTime.now();
    try {
      final info = await PackageInfo.fromPlatform();
      final update = Platform.isAndroid
          ? await _checkPlay(info)
          : Platform.isIOS
          ? await _checkAppStore(info)
          : null;
      if (mounted) setState(() => _update = update);
    } catch (_) {
      // No answer (offline, not from a store): keep what we knew.
    } finally {
      _checking = false;
    }
  }

  Future<_StoreUpdate?> _checkPlay(PackageInfo info) async {
    final url =
        'https://play.google.com/store/apps/details?id=${info.packageName}';
    if (kDebugMode && _debugStoreVersion.isNotEmpty) {
      return _isNewer(_debugStoreVersion, info.version)
          ? _StoreUpdate(url)
          : null;
    }
    final AppUpdateInfo state;
    try {
      state = await InAppUpdate.checkForUpdate();
    } catch (_) {
      // Not installed from Google Play (a debug or side-loaded build): Play cannot tell.
      return null;
    }
    final available =
        state.updateAvailability == UpdateAvailability.updateAvailable ||
        state.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress;
    if (!available) return null;
    final update = _StoreUpdate(
      url,
      playImmediate: state.immediateUpdateAllowed,
    );
    // The full-screen update once per launch; the ribbon (and its button) after that.
    if (update.playImmediate && !_offeredImmediate) {
      _offeredImmediate = true;
      try {
        await InAppUpdate.performImmediateUpdate();
      } catch (_) {
        // Backed out or failed: the ribbon stays.
      }
    }
    return update;
  }

  Future<_StoreUpdate?> _checkAppStore(PackageInfo info) async {
    if (kDebugMode && _debugStoreVersion.isNotEmpty) {
      return _isNewer(_debugStoreVersion, info.version)
          ? _StoreUpdate(
              'https://apps.apple.com/search?term=${Uri.encodeComponent(info.appName)}',
            )
          : null;
    }
    // The person's own store first, then the default one (Apple's lookup answers nothing for
    // some stores, Bangladesh among them, while the default store lists the same version).
    final region = Platform.localeName
        .split(RegExp('[_-]'))
        .skip(1)
        .firstOrNull
        ?.toLowerCase();
    for (final country in <String?>[
      if (region != null && region != 'bd') region,
      null,
    ]) {
      final lookup = await _lookup(info.packageName, country);
      if (lookup == null) continue;
      final (version, url) = lookup;
      return _isNewer(version, info.version) ? _StoreUpdate(url) : null;
    }
    return null;
  }

  /// The App Store's current version and page for a bundle id, or null when it is not listed.
  Future<(String, String)?> _lookup(String bundleId, String? country) async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': bundleId,
      // ignore: use_null_aware_elements (Link still builds with Dart 3.3)
      if (country != null) 'country': country,
      // A fresh answer, not a cached one.
      't': '${DateTime.now().millisecondsSinceEpoch ~/ 60000}',
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return null;
      final body =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;
      final app = results.first as Map<String, dynamic>;
      final version = app['version'] as String?;
      final url = app['trackViewUrl'] as String?;
      return version == null || url == null ? null : (version, url);
    } finally {
      client.close();
    }
  }

  Future<void> _openUpdate() async {
    final update = _update;
    if (update == null) return;
    if (Platform.isAndroid && update.playImmediate) {
      try {
        await InAppUpdate.performImmediateUpdate();
        return;
      } catch (_) {
        // Fall through to the store page.
      }
    }
    await launchUrl(
      Uri.parse(update.url),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_update == null) return widget.child;
    final media = MediaQuery.of(context);
    return Column(
      children: [
        _UpdateRibbon(topInset: media.padding.top, onUpdate: _openUpdate),
        Expanded(
          // The app keeps its own layout below the ribbon, which now holds the status bar space.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// "A new version is ready · Update": calm, always there, no close button.
class _UpdateRibbon extends StatelessWidget {
  const _UpdateRibbon({required this.topInset, required this.onUpdate});

  final double topInset;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return Material(
      color: const Color(0xFF0D0D0D),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topInset + 8, 10, 8),
        child: Row(
          children: [
            const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                english ? 'A new version is ready' : 'নতুন সংস্করণ এসেছে',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onUpdate,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D0D0D),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 34),
                shape: const StadiumBorder(),
              ),
              child: Text(
                english ? 'Update' : 'আপডেট করুন',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// True when [store] is a later version than [installed] ("1.0.10" > "1.0.9").
bool _isNewer(String store, String installed) {
  List<int> parts(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();
  final a = parts(store);
  final b = parts(installed);
  for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

/// For tests: the version comparison the gate uses.
@visibleForTesting
bool appUpdateIsNewer(String store, String installed) =>
    _isNewer(store, installed);
