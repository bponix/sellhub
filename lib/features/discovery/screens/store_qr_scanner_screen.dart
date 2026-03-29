import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/navigation/deep_link_service.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/discovery/presentation/cubit/store_discovery_cubit.dart';
import 'package:sellhub/features/discovery/presentation/store_activator.dart';

class StoreQrScannerScreen extends StatefulWidget {
  const StoreQrScannerScreen({super.key, this.returnTo, this.shellIndex});

  final String? returnTo;
  final int? shellIndex;

  @override
  State<StoreQrScannerScreen> createState() => _StoreQrScannerScreenState();
}

class _StoreQrScannerScreenState extends State<StoreQrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );
  final TextEditingController _domainController = TextEditingController();

  bool _handling = false;
  bool _torchEnabled = false;
  bool _scannerStarted = false;
  String? _statusText;
  DateTime? _lastInvalidAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startScanner());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _domainController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_startScanner());
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_controller.stop());
      _scannerStarted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1513),
      appBar: SellHubTopAppBar(
        title: 'Scan store QR',
        icon: HugeIcons.strokeRoundedQrCode,
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: _torchEnabled ? 'Turn torch off' : 'Turn torch on',
            onPressed: _toggleTorch,
            icon: AppHugeIcon(
              _torchEnabled
                  ? HugeIcons.strokeRoundedFlashOff
                  : HugeIcons.strokeRoundedFlash,
              size: 20,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
            icon: const AppHugeIcon(
              HugeIcons.strokeRoundedCameraRotated01,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            errorBuilder: (context, error, child) {
              return _ScannerStateView(
                icon: HugeIcons.strokeRoundedCameraOff02,
                title: 'Camera unavailable',
                subtitle:
                    error.errorDetails?.message ??
                    'Allow camera access and try again.',
                primaryLabel: 'Retry scanner',
                onPrimaryTap: _startScanner,
                secondaryLabel: 'Enter domain manually',
                onSecondaryTap: _openManualEntry,
              );
            },
            onDetect: (capture) async {
              if (_handling) return;
              final raw = capture.barcodes.isEmpty
                  ? null
                  : capture.barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;
              _handling = true;
              await _handleRawValue(raw.trim());
            },
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.60),
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.70),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          _ScannerFrame(statusText: _statusText),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_statusText != null) ...[
                      _StatusChip(text: _statusText!),
                      const SizedBox(height: 10),
                    ],
                    const _ScannerTipsRow(),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Point the camera at a store QR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SellHub opens store links, product links, or a store domain directly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _openManualEntry,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.white24,
                                    ),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const AppHugeIcon(
                                    HugeIcons.strokeRoundedText,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Enter domain'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _pasteAndResolve,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFDFF55A),
                                    foregroundColor: AppColor.text,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const AppHugeIcon(
                                    HugeIcons.strokeRoundedCopy01,
                                    size: 18,
                                    color: AppColor.text,
                                  ),
                                  label: const Text('Paste link'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startScanner() async {
    try {
      await _controller.start();
      if (mounted) {
        setState(() {
          _scannerStarted = true;
          _statusText ??= 'Ready to scan';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _scannerStarted = false;
          _statusText = 'Unable to start camera';
        });
      }
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() {
      _torchEnabled = !_torchEnabled;
    });
  }

  Future<void> _pasteAndResolve() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _showTransientStatus('Clipboard does not contain a link or domain.');
      return;
    }
    _handling = true;
    await _handleRawValue(text);
  }

  Future<void> _openManualEntry() async {
    await _controller.stop();
    _scannerStarted = false;
    if (!mounted) return;
    final raw = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColor.safe,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text(
                'Enter store domain',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColor.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: `anammart.com` or a full activation link from SellHub.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _domainController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter domain or paste a link',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_domainController.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDFF55A),
                    foregroundColor: AppColor.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Open store'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (raw == null || raw.trim().isEmpty) {
      _domainController.clear();
      await _startScanner();
      return;
    }
    _handling = true;
    await _handleRawValue(raw.trim());
    _domainController.clear();
  }

  Future<void> _handleRawValue(String raw) async {
    try {
      final discoveryCubit = context.read<StoreDiscoveryCubit>();
      final normalizedRaw = raw.trim();
      if (_scannerStarted) {
        await _controller.stop();
        _scannerStarted = false;
      }
      if (mounted) {
        setState(() {
          _statusText = 'Resolving link...';
        });
      }
      final uri = DeepLinkService.normalizeExternalUri(normalizedRaw);
      if (uri != null && DeepLinkService.canHandleUri(uri)) {
        final handled = await DeepLinkService.routeIncomingUri(uri);
        if (!handled) {
          throw Exception('Unable to open this SellHub link.');
        }
        return;
      }
      if (_looksLikeEncodedOrSchemeValue(normalizedRaw) && uri == null) {
        throw Exception('QR contains an unsupported or invalid link format.');
      }
      final domain = _extractDomain(normalizedRaw);
      if (domain == null || domain.isEmpty) {
        throw Exception(
          'QR does not contain a valid SellHub link or store domain.',
        );
      }
      final store = await discoveryCubit.resolveDomain(domain);
      if (!mounted) return;
      setState(() {
        _statusText = 'Opening ${store.title}';
      });
      await StoreActivator.activate(
        context,
        store.toActiveStore(),
        returnTo: widget.returnTo,
        shellIndex: widget.shellIndex,
      );
    } catch (error) {
      if (!mounted) return;
      _showTransientStatus(error.toString().replaceFirst('Exception: ', ''));
      _handling = false;
      await _startScanner();
    }
  }

  void _showTransientStatus(String message) {
    final now = DateTime.now();
    if (_lastInvalidAt != null &&
        now.difference(_lastInvalidAt!).inMilliseconds < 1400) {
      return;
    }
    _lastInvalidAt = now;
    setState(() {
      _statusText = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColor.alert),
    );
  }

  String? _extractDomain(String raw) {
    final direct = raw.trim();
    if (!direct.contains('://') && direct.contains('.')) {
      return direct.toLowerCase();
    }
    final uri = DeepLinkService.normalizeExternalUri(raw);
    if (uri == null) return null;
    final domain = uri.queryParameters['domain']?.trim().toLowerCase();
    if (domain != null && domain.isNotEmpty) return domain;
    if (uri.host.isNotEmpty && uri.host != 'sellhub.bponi.com') {
      return uri.host.toLowerCase();
    }
    return null;
  }

  bool _looksLikeEncodedOrSchemeValue(String raw) {
    return raw.contains('://') ||
        raw.contains('%3A') ||
        raw.contains('%2F') ||
        raw.contains('mailto:') ||
        raw.contains('javascript:');
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({this.statusText});

  final String? statusText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.94),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  _Corner(alignment: Alignment.topLeft),
                  _Corner(alignment: Alignment.topRight),
                  _Corner(alignment: Alignment.bottomLeft),
                  _Corner(alignment: Alignment.bottomRight),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              statusText ?? 'Align the QR code inside the frame',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: alignment == Alignment.topLeft
                ? const Radius.circular(22)
                : Radius.zero,
            topRight: alignment == Alignment.topRight
                ? const Radius.circular(22)
                : Radius.zero,
            bottomLeft: alignment == Alignment.bottomLeft
                ? const Radius.circular(22)
                : Radius.zero,
            bottomRight: alignment == Alignment.bottomRight
                ? const Radius.circular(22)
                : Radius.zero,
          ),
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: Color(0xFFDFF55A), width: 4)
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: Color(0xFFDFF55A), width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFFDFF55A), width: 4)
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Color(0xFFDFF55A), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColor.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ScannerTipsRow extends StatelessWidget {
  const _ScannerTipsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ScannerTipChip(
            icon: HugeIcons.strokeRoundedQrCode,
            label: 'Use store QR',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _ScannerTipChip(
            icon: HugeIcons.strokeRoundedLink01,
            label: 'Or paste link',
          ),
        ),
      ],
    );
  }
}

class _ScannerTipChip extends StatelessWidget {
  const _ScannerTipChip({required this.icon, required this.label});

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppHugeIcon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerStateView extends StatelessWidget {
  const _ScannerStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.onSecondaryTap,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final Future<void> Function() onPrimaryTap;
  final String secondaryLabel;
  final Future<void> Function() onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHugeIcon(icon, size: 40, color: AppColor.neutral2),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPrimaryTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDFF55A),
                    foregroundColor: AppColor.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(primaryLabel),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondaryTap,
                child: Text(secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
