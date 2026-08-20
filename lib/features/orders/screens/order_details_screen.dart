import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_helpers.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_local_store.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_widgets.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/orders/data/models/order_issue_report.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/reseller_profit_proof.dart';
import 'package:sellhub/features/profile/data/model/reseller_payout_evidence.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.siteId,
    required this.order,
  });

  final int siteId;
  final OrderHistoryResModelProfile order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<List<OrderEventModel>> _eventsFuture;
  late Future<SupplierTrustProfile?> _supplierTrustFuture;
  late Future<OrderIssueReport?> _issueReportFuture;
  late Future<ResellerProfitProof?> _profitProofFuture;
  late Future<ResellerPayoutEvidence?> _payoutEvidenceFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = di.sl<OrdersRepository>().fetchOrderEvents(
      siteId: widget.siteId,
      orderId: widget.order.id ?? 0,
    );
    _supplierTrustFuture = _loadSupplierTrust();
    _issueReportFuture = _loadIssueReport();
    _profitProofFuture = _loadProfitProof();
    _payoutEvidenceFuture = _loadPayoutEvidence();
  }

  Future<void> _reload() async {
    setState(() {
      _eventsFuture = di.sl<OrdersRepository>().fetchOrderEvents(
        siteId: widget.siteId,
        orderId: widget.order.id ?? 0,
      );
      _supplierTrustFuture = _loadSupplierTrust();
      _issueReportFuture = _loadIssueReport();
      _profitProofFuture = _loadProfitProof();
      _payoutEvidenceFuture = _loadPayoutEvidence();
    });
    await _eventsFuture;
  }

  Future<SupplierTrustProfile?> _loadSupplierTrust() {
    final store = context.read<StorefrontCubit>().state.siteDetails;
    return di.sl<SupplierTrustLocalStore>().loadProfile(
      siteId: widget.siteId,
      domain: store?.domain?.trim() ?? '',
      title: store?.title?.trim() ?? '',
    );
  }

  Future<OrderIssueReport?> _loadIssueReport() {
    return LocalStorage.getLatestOrderIssueReport(
      siteId: widget.siteId,
      orderId: widget.order.orderId ?? '',
    );
  }

  Future<ResellerProfitProof?> _loadProfitProof() {
    final orderId = widget.order.id ?? 0;
    if (orderId <= 0) return Future.value(null);
    return di.sl<ProfileRepository>().fetchProfitProof(
      siteId: widget.siteId,
      orderId: orderId,
    );
  }

  Future<ResellerPayoutEvidence?> _loadPayoutEvidence() async {
    final orderId = widget.order.id ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (orderId <= 0 || userId <= 0) return null;
    return di.sl<ProfileRepository>().fetchPayoutEvidence(
      userId: userId,
      siteId: widget.siteId,
      orderId: orderId,
    );
  }

  bool _canRequestCancel() {
    final current = widget.order.status ?? 0;
    return current >= 0 && current <= 3;
  }

  Future<void> _showSupportSheet() async {
    final store = context.read<StorefrontCubit>().state.siteDetails;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailsSupportSheet(
        order: widget.order,
        storeTitle: store?.title,
        storePhone: store?.phone?.toString(),
        storeEmail: store?.email,
      ),
    );
  }

  Future<void> _openIssueReportSheet() async {
    final report = await showModalBottomSheet<OrderIssueReport>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OrderIssueReportSheet(
        siteId: widget.siteId,
        orderId: widget.order.orderId ?? 'Order',
      ),
    );
    if (report == null || !mounted) return;
    CustomToast.success('Issue report saved for follow-up.');
    await _reload();
  }

  Future<void> _openSupportSheet() async {
    final cubit = context.read<OrdersCubit>();
    final userId = await LocalStorage.getUserID() ?? 0;
    final ok = await cubit.createCustomerSupportRequest(
      userId: userId,
      siteId: widget.siteId,
      orderId: widget.order.id ?? 0,
      orderLabel: widget.order.orderId ?? 'Order',
    );
    if (!mounted) return;
    if (!ok) {
      final message =
          cubit.state.actionError?.title ?? 'Unable to send support request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Support request sent to the supplier.');
    await _reload();
    if (!mounted) return;
    await _showSupportSheet();
  }

  Future<void> _requestCancel() async {
    final cubit = context.read<OrdersCubit>();
    final userId = await LocalStorage.getUserID() ?? 0;
    final ok = await cubit.createCustomerCancelRequest(
      userId: userId,
      siteId: widget.siteId,
      orderId: widget.order.id ?? 0,
      orderLabel: widget.order.orderId ?? 'Order',
    );
    if (!mounted) return;
    if (!ok) {
      final message =
          cubit.state.actionError?.title ??
          'Unable to send cancellation request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Cancellation request sent to the supplier.');
    await _reload();
  }

  Future<void> _reorder() async {
    final orderId = widget.order.orderId ?? 'Order';
    await Clipboard.setData(ClipboardData(text: orderId));
    if (!mounted) return;
    CustomToast.info(
      'Order ID copied. Use it for buyer follow-up or supplier support.',
    );
  }

  String _nextActionTitle() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return 'Resolve supplier issue';
    }
    if (status >= 10 && widget.order.isSettle != true) {
      return 'Review payout status';
    }
    if (status >= 4) {
      return 'Track fulfillment';
    }
    return 'Keep buyer updated';
  }

  String _nextActionDescription() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return 'Open supplier support, log the issue, and keep the buyer informed on the resolution.';
    }
    if (status >= 10 && widget.order.isSettle != true) {
      return 'Delivery is complete. Check payout timing and profit release next.';
    }
    if (status >= 4) {
      return 'Supplier fulfillment is active. Watch progress here and escalate delays early.';
    }
    return 'The order is still early in the pipeline. Use the order ID for buyer follow-up and confirmation.';
  }

  String _nextActionLabel() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return 'Supplier support';
    }
    if (status >= 10 && widget.order.isSettle != true) {
      return 'Open payouts';
    }
    if (status >= 4) {
      return 'Open support';
    }
    return 'Copy order ID';
  }

  Future<void> _runNextAction() async {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      await _openSupportSheet();
      return;
    }
    if (status >= 10 && widget.order.isSettle != true) {
      if (!mounted) return;
      AppRouter.goToPayouts(context);
      return;
    }
    if (status >= 4) {
      await _openSupportSheet();
      return;
    }
    await _reorder();
  }

  String _riskLabel() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return 'High risk';
    }
    if (status == 7 || status == 9) {
      return 'Closed issue';
    }
    if (status >= 4) {
      return 'Watch delivery';
    }
    return 'Buyer follow-up';
  }

  Color _riskColor() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return AppColor.alert;
    }
    if (status >= 4) {
      return AppColor.warning;
    }
    return const Color(0xFF0E9F6E);
  }

  Color _riskBackground() {
    final status = widget.order.status ?? 0;
    if (widget.order.supportIssue || status == 8) {
      return AppColor.alertLight;
    }
    if (status >= 4) {
      return AppColor.warningLight;
    }
    return const Color(0xFFEAF8F1);
  }

  String _payoutLabel() {
    final status = widget.order.status ?? 0;
    if (widget.order.isSettle == true) {
      return 'Paid out';
    }
    if (status >= 10) {
      return 'Ready for payout';
    }
    if (status >= 4) {
      return 'Clearing now';
    }
    return 'Delivery lock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SellHubTopAppBar(
        title: widget.order.orderId ?? 'Buyer order',
        icon: HugeIcons.strokeRoundedPackageSearch01,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _OrderHero(order: widget.order),
            const SizedBox(height: 16),
            FutureBuilder<ResellerProfitProof?>(
              future: _profitProofFuture,
              builder: (context, snapshot) => _ProfitProofCard(
                proof: snapshot.data,
                loading: snapshot.connectionState == ConnectionState.waiting,
                failed: snapshot.hasError,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<ResellerPayoutEvidence?>(
              future: _payoutEvidenceFuture,
              builder: (context, snapshot) => _PayoutEvidenceCard(
                evidence: snapshot.data,
                loading: snapshot.connectionState == ConnectionState.waiting,
                failed: snapshot.hasError,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                final isBusy =
                    state.actionSubmitting &&
                    state.actionOrderId == widget.order.id;
                return _OrderActionPanel(
                  primaryLabel: _nextActionLabel(),
                  onPrimaryAction: _runNextAction,
                  onSupport: _openSupportSheet,
                  onReportIssue: _openIssueReportSheet,
                  onCopyId: _reorder,
                  onCancel: _canRequestCancel() ? _requestCancel : null,
                  isBusy: isBusy,
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<OrderIssueReport?>(
              future: _issueReportFuture,
              builder: (context, snapshot) {
                final report = snapshot.data;
                if (report == null) return const SizedBox.shrink();
                return Column(
                  children: [
                    _OrderIssueReportCard(report: report),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            FutureBuilder<SupplierTrustProfile?>(
              future: _supplierTrustFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                if (profile == null) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    _OrderSupplierExecutionCard(
                      order: widget.order,
                      profile: profile,
                      supplierName: 'Anonymous fulfillment source',
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nextActionTitle(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColor.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroPill(
                        label: 'Risk ${_riskLabel()}',
                        toneColor: _riskColor(),
                        background: _riskBackground(),
                      ),
                      _HeroPill(
                        label: 'Cash ${_payoutLabel()}',
                        toneColor: AppColor.primary,
                        background: AppColor.primarySoft,
                      ),
                      _HeroPill(
                        label: 'Next ${_nextActionLabel()}',
                        toneColor: const Color(0xFF0E9F6E),
                        background: const Color(0xFFEAF8F1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nextActionDescription(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OrderProgressPanel(order: widget.order),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OrderSectionLead(
                    icon: HugeIcons.strokeRoundedDeliveryTracking01,
                    eyebrow: 'Live updates',
                    title: 'Tracking timeline',
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<OrderEventModel>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 24, bottom: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return _TimelineMessage(
                          icon: HugeIcons.strokeRoundedAlert02,
                          title: 'Unable to load tracking updates',
                          subtitle: 'Pull to refresh and try again.',
                        );
                      }
                      final events = snapshot.data ?? const <OrderEventModel>[];
                      if (events.isEmpty) {
                        return const _TimelineMessage(
                          icon: HugeIcons.strokeRoundedPackage01,
                          title: 'No public events yet',
                          subtitle:
                              'The store has not published tracking updates for this order yet.',
                        );
                      }
                      return Column(
                        children: List.generate(events.length, (index) {
                          final event = events[index];
                          return _TimelineTile(
                            event: event,
                            isLast: index == events.length - 1,
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderActionPanel extends StatelessWidget {
  const _OrderActionPanel({
    required this.primaryLabel,
    required this.onPrimaryAction,
    required this.onSupport,
    required this.onReportIssue,
    required this.onCopyId,
    required this.onCancel,
    this.isBusy = false,
  });

  final String primaryLabel;
  final Future<void> Function() onPrimaryAction;
  final VoidCallback onSupport;
  final VoidCallback onReportIssue;
  final VoidCallback onCopyId;
  final VoidCallback? onCancel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBusy ? null : onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDFF55A),
                foregroundColor: AppColor.text,
                elevation: 0,
              ),
              child: Text(primaryLabel),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OrderActionChip(
                label: 'Support',
                icon: HugeIcons.strokeRoundedHelpCircle,
                onTap: onSupport,
                isBusy: isBusy,
              ),
              _OrderActionChip(
                label: 'Report issue',
                icon: HugeIcons.strokeRoundedAlert02,
                onTap: onReportIssue,
              ),
              _OrderActionChip(
                label: 'Copy ID',
                icon: HugeIcons.strokeRoundedReload,
                onTap: onCopyId,
              ),
              if (onCancel != null)
                _OrderActionChip(
                  label: 'Cancel',
                  icon: HugeIcons.strokeRoundedCancel01,
                  onTap: onCancel!,
                  isBusy: isBusy,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderIssueReportCard extends StatelessWidget {
  const _OrderIssueReportCard({required this.report});

  final OrderIssueReport report;

  @override
  Widget build(BuildContext context) {
    final brief = StringBuffer('SellHub issue brief\n')
      ..writeln('Order: ${report.orderId}')
      ..writeln('Issue: ${report.issueType}')
      ..writeln('Status: ${report.status}')
      ..writeln('Updated: ${formatDateTime(report.updatedAt)}');
    if (report.note.trim().isNotEmpty) {
      brief.writeln('Note: ${report.note.trim()}');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.alertLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.alert),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppHugeIcon(
                HugeIcons.strokeRoundedAlert02,
                size: 18,
                color: AppColor.alert,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Issue follow-up',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _HeroPill(
                label: report.status,
                toneColor: AppColor.alert,
                background: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${report.issueType} • ${formatDateTime(report.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.alert,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (report.note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              report.note,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: brief.toString()));
                if (!context.mounted) return;
                CustomToast.success('Issue brief copied');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy issue brief'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionChip extends StatelessWidget {
  const _OrderActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isBusy = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isBusy ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColor.safe1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColor.safe),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              AppHugeIcon(icon, size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Text(
              isBusy ? 'Sending...' : label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitProofCard extends StatelessWidget {
  const _ProfitProofCard({
    required this.proof,
    required this.loading,
    required this.failed,
  });

  final ResellerProfitProof? proof;
  final bool loading;
  final bool failed;

  static const Map<String, String> _statusLabels = <String, String>{
    'paid': 'Profit paid',
    'withdrawable': 'Profit withdrawable',
    'pending': 'Profit pending',
    'reversed': 'Profit reversed',
    'proof_needed': 'Needs proof',
    'no_profit': 'No profit',
    'quote_only': 'Quote only',
  };

  @override
  Widget build(BuildContext context) {
    final value = proof;
    final line = value?.lineSummary;
    final title = loading
        ? 'Checking Store profit proof'
        : failed || value == null
        ? 'Profit proof unavailable'
        : _statusLabels[value.proofStatus] ?? value.proofStatus;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: failed ? AppColor.warning : AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: failed ? AppColor.warningLight : AppColor.safe1,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AppHugeIcon(
                  failed
                      ? HugeIcons.strokeRoundedAlert02
                      : HugeIcons.strokeRoundedMoneyBag02,
                  size: 20,
                  color: failed ? AppColor.warning : AppColor.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESELLER PROFIT PROOF',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            failed || value == null
                ? 'Do not rely on the displayed order margin until Store proof is available.'
                : 'Store links buyer price, base cost, anonymous supplier lines, commission, wallet movement, payout, and reversals.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
          ),
          if (value != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProfitMetric(
                  label: 'Buyer paid',
                  value: _currency(
                    value.orderResellAmount > 0
                        ? value.orderResellAmount
                        : line?.buyerTotal,
                  ),
                ),
                _ProfitMetric(
                  label: 'Base cost',
                  value: _currency(line?.baseTotal),
                ),
                _ProfitMetric(
                  label: 'Expected',
                  value: _currency(
                    line?.expectedProfit ?? value.orderResellerCommission,
                  ),
                ),
                _ProfitMetric(
                  label: 'Wallet',
                  value: _currency(value.orderResellerCommission),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${line?.supplierCount ?? 0} anonymous source${(line?.supplierCount ?? 0) == 1 ? '' : 's'} · ${value.proofRows.length} proof row${value.proofRows.length == 1 ? '' : 's'}${value.quoteId == null ? '' : ' · Quote #${value.quoteId} ${value.conversionStatus ?? ''}'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (value.buckets.any((bucket) => bucket.amount > 0)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: value.buckets
                    .where((bucket) => bucket.amount > 0)
                    .take(6)
                    .map(
                      (bucket) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.safe1,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${bucket.key.replaceAll('_', ' ')} ${_currency(bucket.amount)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfitMetric extends StatelessWidget {
  const _ProfitMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 134,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColor.safe1,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColor.neutral2),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _PayoutEvidenceCard extends StatelessWidget {
  const _PayoutEvidenceCard({
    required this.evidence,
    required this.loading,
    required this.failed,
  });

  final ResellerPayoutEvidence? evidence;
  final bool loading;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final value = evidence;
    final blocked =
        value != null &&
        const {'disputed', 'reversed', 'proof_needed'}.contains(value.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: failed || blocked ? AppColor.warning : AppColor.safe,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppHugeIcon(
                blocked
                    ? HugeIcons.strokeRoundedAlert02
                    : HugeIcons.strokeRoundedWallet02,
                size: 20,
                color: blocked ? AppColor.warning : AppColor.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ORDER-TO-WITHDRAWAL EVIDENCE',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loading
                          ? 'Checking wallet and payout proof'
                          : failed || value == null
                          ? 'Payout evidence unavailable'
                          : value.status.replaceAll('_', ' '),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProfitMetric(
                  label: 'Expected',
                  value: _currency(value.expectedProfit),
                ),
                _ProfitMetric(
                  label: 'Wallet credit',
                  value: _currency(value.walletCreditedAmount),
                ),
                _ProfitMetric(
                  label: 'Allocated',
                  value: _currency(value.allocatedAmount),
                ),
                _ProfitMetric(
                  label: 'Proof gap',
                  value: _currency(
                    value.orderProofGap + value.payoutAllocationGap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value.nextAction,
              style: const TextStyle(
                color: AppColor.neutral2,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (value.blockers.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...value.blockers.map(
                (blocker) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    blocker,
                    style: const TextStyle(
                      color: AppColor.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DetailsSupportSheet extends StatelessWidget {
  const _DetailsSupportSheet({
    required this.order,
    required this.storeTitle,
    required this.storePhone,
    required this.storeEmail,
  });

  final OrderHistoryResModelProfile order;
  final String? storeTitle;
  final String? storePhone;
  final String? storeEmail;

  @override
  Widget build(BuildContext context) {
    final orderId = order.orderId ?? 'Order';
    final status = _OrderHero._statusNames[order.status] ?? 'Pending';
    final cashState = order.isSettle == true
        ? 'Paid out'
        : (order.status ?? 0) >= 10
        ? 'Ready for payout'
        : (order.status ?? 0) >= 4
        ? 'Clearing now'
        : 'Delivery lock';
    final rows = <({String label, String value})>[
      (label: 'Order', value: orderId),
      (label: 'Status', value: status),
      (label: 'Cash', value: cashState),
      if ((order.customerPhone?.toString().trim().isNotEmpty ?? false))
        (label: 'Buyer', value: order.customerPhone!.toString().trim()),
      if ((storeTitle ?? '').trim().isNotEmpty)
        (label: 'Store', value: storeTitle!.trim()),
      if ((storePhone ?? '').trim().isNotEmpty)
        (label: 'Phone', value: storePhone!.trim()),
      if ((storeEmail ?? '').trim().isNotEmpty)
        (label: 'Email', value: storeEmail!.trim()),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ready support context for this order.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DetailsSupportRow(label: row.label, value: row.value),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final buffer = StringBuffer('SellHub support brief\n');
                for (final row in rows) {
                  buffer.writeln('${row.label}: ${row.value}');
                }
                await Clipboard.setData(ClipboardData(text: buffer.toString()));
                if (!context.mounted) return;
                CustomToast.success('Support brief copied');
                Navigator.of(context).pop();
              },
              child: const Text('Copy support brief'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSupportRow extends StatelessWidget {
  const _DetailsSupportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderIssueReportSheet extends StatefulWidget {
  const _OrderIssueReportSheet({required this.siteId, required this.orderId});

  final int siteId;
  final String orderId;

  @override
  State<_OrderIssueReportSheet> createState() => _OrderIssueReportSheetState();
}

class _OrderIssueReportSheetState extends State<_OrderIssueReportSheet> {
  final _noteController = TextEditingController();
  String _issueType = 'Supplier problem';

  static const List<String> _issueTypes = <String>[
    'Supplier problem',
    'Buyer fraud',
    'Delivery problem',
    'Payout follow-up',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report order issue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Capture the issue once so follow-up stays consistent.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _issueTypes
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type),
                      selected: _issueType == type,
                      onSelected: (_) {
                        setState(() {
                          _issueType = type;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Issue note',
                hintText: 'What happened and what should happen next?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final report = OrderIssueReport(
                    id: 'issue-${DateTime.now().millisecondsSinceEpoch}',
                    siteId: widget.siteId,
                    orderId: widget.orderId,
                    issueType: _issueType,
                    note: _noteController.text.trim(),
                    status: 'Open',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  await LocalStorage.upsertOrderIssueReport(report);
                  if (!mounted) return;
                  navigator.pop(report);
                },
                child: const Text('Save issue brief'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.order});

  final OrderHistoryResModelProfile order;

  static const Map<int, String> _statusNames = <int, String>{
    0: 'Processing',
    1: 'Placed',
    2: 'Confirmed',
    3: 'Packaging',
    4: 'Packaged',
    5: 'Shipping',
    6: 'Review',
    7: 'Rejected',
    8: 'Returned',
    9: 'Canceled',
    10: 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderId ?? 'Order',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
              ),
              _HeroPill(
                label: _statusNames[order.status] ?? 'Pending',
                toneColor: AppColor.primary,
                background: AppColor.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName ?? 'Buyer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
              ),
              Text(
                order.isSettle == true ? 'Settled' : 'Payout pending',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.customerPhone ?? ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                label: 'Sell ${_currency(order.total)}',
                toneColor: AppColor.primary,
                background: AppColor.primarySoft,
              ),
              _HeroPill(
                label: 'Margin ${_currency(order.profit)}',
                toneColor: const Color(0xFF0E9F6E),
                background: const Color(0xFFEAF8F1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OrderMetaRow(label: 'Buyer', value: order.customerName ?? 'Buyer'),
          _OrderMetaRow(label: 'Phone', value: '${order.customerPhone ?? ''}'),
          _OrderMetaRow(
            label: 'Delivery',
            value: order.customerAddress ?? 'No address provided',
          ),
          if ((order.customerNote ?? '').trim().isNotEmpty)
            _OrderMetaRow(label: 'Note', value: order.customerNote!.trim()),
        ],
      ),
    );
  }
}

class _OrderSupplierExecutionCard extends StatelessWidget {
  const _OrderSupplierExecutionCard({
    required this.order,
    required this.profile,
    required this.supplierName,
  });

  final OrderHistoryResModelProfile order;
  final SupplierTrustProfile profile;
  final String supplierName;

  bool get _isDelivered => (order.status ?? 0) >= 10;

  bool get _isDelayed {
    if (_isDelivered) return false;
    final updatedAt = order.updatedAt ?? order.createdAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt).inDays >= 3;
  }

  String get _slaLabel {
    final avgDays = profile.averageDeliveryDays ?? 0;
    if (avgDays > 0 && avgDays <= 2.5) return 'Fast SLA';
    if (avgDays > 0 && avgDays <= 4.5) return 'Normal SLA';
    return 'Watch SLA';
  }

  String get _escalationTitle {
    if (order.supportIssue || order.status == 8) {
      return 'Supplier escalation running';
    }
    if (_isDelayed) {
      return 'Escalate now';
    }
    if (_isDelivered && order.isSettle != true) {
      return 'Watch payout batch';
    }
    return 'Healthy execution';
  }

  String get _escalationDescription {
    if (order.supportIssue || order.status == 8) {
      return 'A supplier-side issue is already open. Keep buyer updates tight until resolution closes.';
    }
    if (_isDelayed) {
      return 'This order has no fresh movement for 3+ days. Push supplier follow-up before payout risk grows.';
    }
    if (_isDelivered && order.isSettle != true) {
      return 'Delivery is done. Margin should move into the next payout batch unless a dispute opens.';
    }
    return 'Supplier health is acceptable for this order. Continue normal buyer follow-up.';
  }

  String get _batchLabel {
    if (order.isSettle == true) return 'Paid in batch';
    if (order.supportIssue || order.status == 8) return 'Batch blocked';
    if (_isDelivered) return 'Next payout batch';
    return 'Batch locked';
  }

  Color get _batchColor {
    if (order.isSettle == true) return AppColor.green;
    if (order.supportIssue || order.status == 8) return AppColor.alert;
    if (_isDelivered) return AppColor.primary;
    return AppColor.warning;
  }

  Color get _batchBackground {
    if (order.isSettle == true) return const Color(0xFFEAF8F1);
    if (order.supportIssue || order.status == 8) return AppColor.alertLight;
    if (_isDelivered) return AppColor.primarySoft;
    return AppColor.warningLight;
  }

  @override
  Widget build(BuildContext context) {
    final trustStyle = supplierTrustBandStyleForScore(profile.score);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SupplierTrustScoreBadge(score: profile.score, compact: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier execution truth',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supplierName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                label: _slaLabel,
                toneColor: trustStyle.color,
                background: trustStyle.softColor,
              ),
              _HeroPill(
                label:
                    'Issue floor ${formatTrustPercent(profile.minimumIssueRate)}',
                toneColor: (profile.minimumIssueRate ?? 100) <= 3
                    ? AppColor.green
                    : AppColor.warning,
                background: (profile.minimumIssueRate ?? 100) <= 3
                    ? const Color(0xFFEAF8F1)
                    : AppColor.warningLight,
              ),
              _HeroPill(
                label: _batchLabel,
                toneColor: _batchColor,
                background: _batchBackground,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _escalationTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _escalationDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          SupplierTrustCompactFacts(profile: profile),
        ],
      ),
    );
  }
}

String _currency(num? value) => '৳ ${(value ?? 0).toStringAsFixed(0)}';

class _OrderProgressPanel extends StatelessWidget {
  const _OrderProgressPanel({required this.order});

  final OrderHistoryResModelProfile order;

  static const List<_ProgressStep> _steps = <_ProgressStep>[
    _ProgressStep('Placed', HugeIcons.strokeRoundedShoppingBag01),
    _ProgressStep('Confirmed', HugeIcons.strokeRoundedCheckmarkCircle02),
    _ProgressStep('Packed', HugeIcons.strokeRoundedPackageProcess),
    _ProgressStep('Delivered', HugeIcons.strokeRoundedDeliveryTruck02),
  ];

  int _stageIndex() {
    final status = order.status ?? 0;
    if (status >= 10) return 3;
    if (status >= 4) return 2;
    if (status >= 2) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _stageIndex();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OrderSectionLead(
            icon: HugeIcons.strokeRoundedPackageProcess,
            eyebrow: 'Delivery status',
            title: 'Order progress',
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isActive = index <= currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColor.primarySoft
                                  : AppColor.safe1,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive
                                    ? AppColor.primary
                                    : AppColor.safe,
                              ),
                            ),
                            child: AppHugeIcon(
                              step.icon,
                              size: 18,
                              color: isActive
                                  ? AppColor.primary
                                  : AppColor.neutral1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: isActive
                                      ? AppColor.text
                                      : AppColor.neutral2,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (index != _steps.length - 1)
                      Container(
                        width: 18,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 28),
                        color: index < currentStep
                            ? AppColor.primary
                            : AppColor.safe,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep {
  const _ProgressStep(this.label, this.icon);

  final String label;
  final List<List<dynamic>> icon;
}

class _OrderSectionLead extends StatelessWidget {
  const _OrderSectionLead({
    required this.icon,
    required this.eyebrow,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColor.safe),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColor.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.label,
    required this.toneColor,
    required this.background,
  });

  final String label;
  final Color toneColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: toneColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderMetaRow extends StatelessWidget {
  const _OrderMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColor.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          AppHugeIcon(icon, size: 34, color: AppColor.neutral2),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event, required this.isLast});

  final OrderEventModel event;
  final bool isLast;

  static const Map<int, String> _eventNames = <int, String>{
    0: 'Order created',
    1: 'Order received',
    2: 'Confirmed',
    3: 'Preparing',
    4: 'Packed',
    5: 'Shipped',
    6: 'On review',
    7: 'Rejected',
    8: 'Returned',
    9: 'Canceled',
    10: 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    final title = event.note.trim().isNotEmpty
        ? event.note.trim()
        : (_eventNames[event.eventType] ?? 'Order update');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.24),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 72, color: AppColor.safe),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColor.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatDateTime(event.createdAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                  ),
                  if (event.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.address.trim(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
