import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart' as play_update;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/config/app_text.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/updates/app_update_checker.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  final AppUpdateChecker _checker = AppUpdateChecker();
  bool _checking = false;
  bool _performingImmediateUpdate = false;
  AppUpdateCheckResult? _update;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate(force: true));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdate(force: true));
    }
  }

  Future<void> _checkForUpdate({required bool force}) async {
    if (_checking || kIsWeb || !mounted) return;
    _checking = true;
    try {
      final info = await _checker.check(force: force);
      if (!mounted) return;
      setState(() {
        _update = info?.required == true ? info : null;
      });
      if (_update != null && Platform.isAndroid) {
        await _maybeStartImmediateAndroidUpdate(_update!);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Store app update gate check failed: $error',
        stackTrace: stackTrace,
        name: 'store.app_update_gate',
      );
    } finally {
      _checking = false;
    }
  }

  Future<void> _maybeStartImmediateAndroidUpdate(
    AppUpdateCheckResult info,
  ) async {
    if (!Platform.isAndroid ||
        !info.useImmediate ||
        _performingImmediateUpdate) {
      return;
    }
    _performingImmediateUpdate = true;
    try {
      await play_update.InAppUpdate.performImmediateUpdate();
    } catch (error, stackTrace) {
      developer.log(
        'Immediate Android update failed: $error',
        stackTrace: stackTrace,
        name: 'store.app_update_gate',
      );
    } finally {
      _performingImmediateUpdate = false;
    }
  }

  Future<void> _openStore() async {
    final info = _update;
    if (info == null) return;
    if (Platform.isAndroid) {
      final packageInfo = await PackageInfo.fromPlatform();
      final marketUri = Uri.parse(
        'market://details?id=${packageInfo.packageName}',
      );
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=${packageInfo.packageName}',
      );
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return;
    }
    final url = info.storeUrl;
    if (url == null || url.trim().isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_update == null) {
      return widget.child;
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        ColoredBox(
          color: colorScheme.surface.withValues(alpha: 0.96),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColor.safe),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColor.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const AppHugeIcon(
                            HugeIcons.strokeRoundedArrowReloadVertical,
                            color: AppColor.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Update required',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColor.text,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _update!.message?.trim().isNotEmpty == true
                              ? _update!.message!
                              : 'A newer version of ${AppText.appName} is required to continue.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColor.neutral2, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        _VersionRow(
                          label: 'Installed',
                          value: _update!.currentVersion ?? 'Current build',
                        ),
                        const SizedBox(height: 8),
                        _VersionRow(
                          label: 'Latest',
                          value: _update!.storeVersion ?? 'Store build',
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _openStore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDFF55A),
                              foregroundColor: AppColor.text,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Update now',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
