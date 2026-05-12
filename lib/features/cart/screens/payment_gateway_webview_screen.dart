import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum PaymentGatewayWebViewResult { success, failed, cancelled }

class PaymentGatewayWebViewScreen extends StatefulWidget {
  const PaymentGatewayWebViewScreen({
    super.key,
    required this.title,
    required this.initialPayload,
    required this.successUrl,
    required this.failUrl,
    required this.cancelUrl,
  });

  final String title;
  final String initialPayload;
  final String successUrl;
  final String failUrl;
  final String cancelUrl;

  @override
  State<PaymentGatewayWebViewScreen> createState() =>
      _PaymentGatewayWebViewScreenState();
}

class _PaymentGatewayWebViewScreenState
    extends State<PaymentGatewayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final result = _matchResult(request.url);
            if (result != null) {
              _finish(result);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      );

    final payload = widget.initialPayload.trim();
    if (_looksLikeUrl(payload)) {
      _controller.loadRequest(Uri.parse(_normalizeUrl(payload)));
    } else {
      _controller.loadHtmlString(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_completed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_completed) {
          _finish(PaymentGatewayWebViewResult.cancelled);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: SellHubTopAppBar(
          title: widget.title,
          icon: HugeIcons.strokeRoundedWallet02,
          showBackButton: true,
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
          ],
        ),
      ),
    );
  }

  PaymentGatewayWebViewResult? _matchResult(String url) {
    final normalized = _normalizeUrl(url);
    if (_matchesUrl(normalized, widget.successUrl) ||
        _hasCallbackKeyword(normalized, const <String>[
          'payment-success',
          '/success',
          'status=success',
        ])) {
      return PaymentGatewayWebViewResult.success;
    }
    if (_matchesUrl(normalized, widget.cancelUrl) ||
        _hasCallbackKeyword(normalized, const <String>[
          'payment-cancel',
          '/cancel',
          'status=cancel',
          'status=cancelled',
        ])) {
      return PaymentGatewayWebViewResult.cancelled;
    }
    if (_matchesUrl(normalized, widget.failUrl) ||
        _hasCallbackKeyword(normalized, const <String>[
          'payment-fail',
          '/fail',
          'status=fail',
          'status=failed',
          'status=error',
        ])) {
      return PaymentGatewayWebViewResult.failed;
    }
    return null;
  }

  bool _hasCallbackKeyword(String value, List<String> keywords) {
    if (value.isEmpty || value.startsWith('about:') || value.startsWith('data:')) {
      return false;
    }
    final lower = value.toLowerCase();
    return keywords.any(lower.contains);
  }

  bool _matchesUrl(String left, String right) {
    final normalizedRight = _normalizeUrl(right);
    if (normalizedRight.isEmpty) return false;
    return left.startsWith(normalizedRight);
  }

  bool _looksLikeUrl(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('www.');
  }

  String _normalizeUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  void _finish(PaymentGatewayWebViewResult result) {
    if (_completed || !mounted) return;
    _completed = true;
    Navigator.of(context).pop(result);
  }
}
