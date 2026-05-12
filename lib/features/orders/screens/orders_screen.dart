import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_helpers.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_local_store.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_widgets.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/orders/data/models/order_issue_report.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';
import 'package:sellhub/features/orders/screens/order_details_screen.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const Map<int, String> statusNames = <int, String>{
    0: 'Processing',
    1: 'Placed',
    2: 'Confirmed',
    3: 'Packaging',
    4: 'Packaged',
    5: 'Shipping',
    6: 'Review',
    7: 'Rejected',
    8: 'Return',
    9: 'Canceled',
    10: 'Delivered',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<OrdersCubit>()
        ..fetchOrders(siteId: StoreScope.activeSiteId(context), customerId: 0),
      child: const _OrdersControlCenter(),
    );
  }
}

enum _OrderQueueTab {
  needsAction,
  awaitingBuyerConfirmation,
  sentToSupplier,
  fulfillmentInProgress,
  delivered,
  atRisk,
  returnIssue,
  payoutPending,
}

class _OrdersControlCenter extends StatefulWidget {
  const _OrdersControlCenter();

  @override
  State<_OrdersControlCenter> createState() => _OrdersControlCenterState();
}

class _OrdersControlCenterState extends State<_OrdersControlCenter> {
  int _customerId = 0;
  _OrderQueueTab _selectedTab = _OrderQueueTab.needsAction;
  late Future<SupplierTrustProfile?> _supplierTrustFuture;
  Map<String, OrderIssueReport> _latestIssueReports =
      const <String, OrderIssueReport>{};
  Map<String, PayoutDisputeEntry> _latestPayoutDisputes =
      const <String, PayoutDisputeEntry>{};

  @override
  void initState() {
    super.initState();
    _supplierTrustFuture = _loadSupplierTrust();
    _loadOrders();
  }

  Future<SupplierTrustProfile?> _loadSupplierTrust() {
    final storefront = context.read<StorefrontCubit>().state.siteDetails;
    return di.sl<SupplierTrustLocalStore>().loadProfile(
      siteId: StoreScope.activeSiteId(context),
      domain: storefront?.domain?.trim() ?? '',
      title: storefront?.title?.trim() ?? '',
    );
  }

  Future<void> _loadOrders() async {
    final customerId = await LocalStorage.getCustomerID() ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    _customerId = customerId;
    final issueReports = await _loadLatestIssueReports();
    final payoutDisputes = await _loadLatestPayoutDisputes(userId: userId);
    if (!mounted) return;
    setState(() {
      _supplierTrustFuture = _loadSupplierTrust();
      _latestIssueReports = issueReports;
      _latestPayoutDisputes = payoutDisputes;
    });
    await context.read<OrdersCubit>().fetchOrders(
      siteId: StoreScope.activeSiteId(context),
      customerId: customerId,
    );
  }

  Future<Map<String, OrderIssueReport>> _loadLatestIssueReports() async {
    final siteId = StoreScope.activeSiteId(context);
    final reports = await LocalStorage.getOrderIssueReports();
    final latest = <String, OrderIssueReport>{};
    for (final report in reports.where((item) => item.siteId == siteId)) {
      final orderKey = report.orderId.trim().toLowerCase();
      if (orderKey.isEmpty) continue;
      final current = latest[orderKey];
      if (current == null || report.updatedAt.isAfter(current.updatedAt)) {
        latest[orderKey] = report;
      }
    }
    return latest;
  }

  Future<Map<String, PayoutDisputeEntry>> _loadLatestPayoutDisputes({
    required int userId,
  }) async {
    if (userId <= 0) return const <String, PayoutDisputeEntry>{};
    final siteId = StoreScope.activeSiteId(context);
    final reports = await di.sl<ProfileRepository>().fetchPayoutDisputes(
      userId: userId,
      siteId: siteId,
    );
    final latest = <String, PayoutDisputeEntry>{};
    for (final report in reports.where((item) => item.siteId == siteId)) {
      final orderKey = report.orderId.trim().toLowerCase();
      if (orderKey.isEmpty) continue;
      final current = latest[orderKey];
      final currentUpdated = current?.updatedAt ?? current?.createdAt;
      final reportUpdated = report.updatedAt ?? report.createdAt;
      if (current == null ||
          (reportUpdated != null &&
              (currentUpdated == null || reportUpdated.isAfter(currentUpdated)))) {
        latest[orderKey] = report;
      }
    }
    return latest;
  }

  Future<void> _copyOrderId(OrderHistoryResModelProfile order) async {
    await Clipboard.setData(ClipboardData(text: order.orderId ?? 'Order'));
    if (!mounted) return;
    CustomToast.info('Order ID copied');
  }

  Future<void> _messageBuyer(OrderHistoryResModelProfile order) async {
    final message = StringBuffer()
      ..writeln('Assalamu Alaikum ${order.customerName ?? 'Buyer'},')
      ..writeln('Your order ${order.orderId ?? ''} is being followed up.')
      ..writeln('Amount: ${_currency(order.total)}')
      ..writeln(
        'Status: ${OrdersScreen.statusNames[order.status] ?? 'Pending'}',
      );
    await Clipboard.setData(ClipboardData(text: message.toString()));
    if (!mounted) return;
    CustomToast.info('Buyer message copied');
  }

  Future<void> _messageSupplierSupport(
    OrderHistoryResModelProfile order,
  ) async {
    final cubit = context.read<OrdersCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    final ok = await cubit.createCustomerSupportRequest(
      userId: userId,
      siteId: siteId,
      orderId: order.id ?? 0,
      orderLabel: order.orderId ?? 'Order',
    );
    if (!mounted) return;
    if (!ok) {
      CustomToast.error(
        cubit.state.actionError?.title ?? 'Unable to message supplier support.',
      );
      return;
    }
    CustomToast.success('Supplier support request logged');
    await _loadOrders();
  }

  Future<void> _raiseIssue(OrderHistoryResModelProfile order) async {
    final cubit = context.read<OrdersCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    final ok = await cubit.createCustomerIssueRequest(
      userId: userId,
      siteId: siteId,
      orderId: order.id ?? 0,
      orderLabel: order.orderId ?? 'Order',
    );
    if (!mounted) return;
    if (!ok) {
      CustomToast.error(
        cubit.state.actionError?.title ?? 'Unable to raise issue.',
      );
      return;
    }
    CustomToast.success('Issue flagged for supplier review');
    await _loadOrders();
  }

  OrderIssueReport? _issueReportFor(OrderHistoryResModelProfile order) {
    final orderId = (order.orderId ?? '').trim().toLowerCase();
    if (orderId.isEmpty) return null;
    return _latestIssueReports[orderId];
  }

  bool _hasActiveIssue(
    OrderHistoryResModelProfile order, [
    OrderIssueReport? issueReport,
  ]) {
    if (order.status == 8 || order.supportIssue) return true;
    final localIssue = issueReport ?? _issueReportFor(order);
    if (localIssue == null) return false;
    return localIssue.status.trim().toLowerCase() != 'closed';
  }

  PayoutDisputeEntry? _payoutDisputeFor(OrderHistoryResModelProfile order) {
    final orderId = (order.orderId ?? '').trim().toLowerCase();
    if (orderId.isEmpty) return null;
    return _latestPayoutDisputes[orderId];
  }

  bool _hasActivePayoutDispute(
    OrderHistoryResModelProfile order, [
    PayoutDisputeEntry? dispute,
  ]) {
    final payoutDispute = dispute ?? _payoutDisputeFor(order);
    if (payoutDispute == null) return false;
    return payoutDispute.status.trim().toLowerCase() != 'resolved' &&
        payoutDispute.status.trim().toLowerCase() != 'closed';
  }

  List<OrderHistoryResModelProfile> _applyQueue(
    List<OrderHistoryResModelProfile> orders,
  ) {
    final filtered = orders
        .where((order) {
          final profile = _executionProfile(order);
          switch (_selectedTab) {
            case _OrderQueueTab.needsAction:
              return profile.nextActionLabel != 'Watch only';
            case _OrderQueueTab.awaitingBuyerConfirmation:
              return profile.needsBuyerContact &&
                  (order.status ?? 0) <= 2 &&
                  !_isDelivered(order);
            case _OrderQueueTab.sentToSupplier:
              return (order.status ?? 0) >= 1 && (order.status ?? 0) <= 2;
            case _OrderQueueTab.fulfillmentInProgress:
              return (order.status ?? 0) >= 3 && (order.status ?? 0) <= 5;
            case _OrderQueueTab.delivered:
              return _isDelivered(order);
            case _OrderQueueTab.atRisk:
              return profile.atRisk;
            case _OrderQueueTab.returnIssue:
              return _hasActiveIssue(order);
            case _OrderQueueTab.payoutPending:
              return profile.unpaid;
          }
        })
        .toList(growable: false);
    filtered.sort((a, b) => _urgencyScore(b).compareTo(_urgencyScore(a)));
    return filtered;
  }

  String _fulfillmentStatus(OrderHistoryResModelProfile order) =>
      OrdersScreen.statusNames[order.status] ?? 'Pending';

  String _payoutStatus(OrderHistoryResModelProfile order) {
    if (_isDelivered(order) && order.isSettle == true) return 'Paid';
    if (_isDelivered(order) && order.isSettle != true) return 'Payout pending';
    return 'Locked until delivery';
  }

  String _queueCashState(
    OrderHistoryResModelProfile order, [
    PayoutDisputeEntry? payoutDispute,
  ]) {
    final dispute = payoutDispute ?? _payoutDisputeFor(order);
    if (dispute != null &&
        dispute.status.trim().toLowerCase() != 'resolved' &&
        dispute.status.trim().toLowerCase() != 'closed') {
      return 'Dispute hold';
    }
    if (_isDelivered(order) && order.isSettle == true) return 'Paid out';
    if (_isDelivered(order) && order.isSettle != true) return 'Ready for payout';
    if ((order.status ?? 0) >= 3) return 'Clearing now';
    return 'Delivery lock';
  }

  String _nextBestAction(
    OrderHistoryResModelProfile order, [
    OrderIssueReport? issueReport,
  ]) {
    if (order.status == 8) return 'Resolve return';
    if (_hasActiveIssue(order, issueReport)) return 'Supplier follow-up';
    if (_hasActivePayoutDispute(order)) return 'Track payout';
    if (_isDelayed(order)) return 'Unblock delayed order';
    if (!_isDelivered(order) && !order.buyerContacted) return 'Contact buyer';
    if (_isDelivered(order) && order.isSettle != true) return 'Track payout';
    if ((order.status ?? 0) >= 3 && (order.status ?? 0) <= 5) {
      return 'Track fulfillment';
    }
    return 'Watch only';
  }

  bool _isDelivered(OrderHistoryResModelProfile order) =>
      (order.status ?? 0) >= 10;

  bool _isDelayed(OrderHistoryResModelProfile order) {
    if (_isDelivered(order)) return false;
    final updatedAt = order.updatedAt ?? order.createdAt;
    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt).inDays >= 3;
  }

  int _urgencyScore(OrderHistoryResModelProfile order) {
    final issueReport = _issueReportFor(order);
    final payoutDispute = _payoutDisputeFor(order);
    var score = 0;
    if (order.status == 8) score += 100;
    if (_hasActiveIssue(order, issueReport)) score += 80;
    if (_hasActivePayoutDispute(order, payoutDispute)) score += 45;
    if (_isDelayed(order)) score += 60;
    if (!_isDelivered(order) && !order.buyerContacted) score += 50;
    if (_isDelivered(order) && order.isSettle != true) score += 40;
    if ((order.profit ?? 0) >= 200) score += 10;
    if ((order.status ?? 0) >= 3 && (order.status ?? 0) <= 5) score += 15;
    return score;
  }

  _OrderExecutionProfile _executionProfile(OrderHistoryResModelProfile order) {
    final issueReport = _issueReportFor(order);
    final payoutDispute = _payoutDisputeFor(order);
    final delivered = _isDelivered(order);
    final delayed = _isDelayed(order);
    final unpaid = delivered && order.isSettle != true;
    final profitable = (order.profit ?? 0) > 0;
    final highProfit = (order.profit ?? 0) >= 200;
    final needsBuyerContact = !delivered && !order.buyerContacted;
    final atRisk = _hasActiveIssue(order, issueReport) ||
        _hasActivePayoutDispute(order, payoutDispute) ||
        delayed ||
        ((order.status ?? 0) >= 7 && !delivered);
    final nextAction = _nextBestAction(order, issueReport);
    final nextReason = switch (nextAction) {
      'Resolve return' =>
        'Return or rejection risk is active. Fix this before pushing more orders.',
      'Supplier follow-up' =>
        issueReport == null
            ? 'A support flag is already open. Push supplier resolution now.'
            : '${issueReport.issueType} is open. Push supplier resolution now.',
      'Unblock delayed order' =>
        'No fresh progress for 3+ days. This order needs intervention.',
      'Contact buyer' =>
        'Buyer follow-up is still missing. Contact first to avoid leakage.',
      'Track payout' =>
        _hasActivePayoutDispute(order, payoutDispute)
            ? '${payoutDispute?.reason ?? 'Payout mismatch'} is still open.'
            : 'Order is delivered but margin is not settled yet.',
      'Track fulfillment' =>
        'Supplier is moving the order. Watch delivery progress closely.',
      _ => 'No urgent blocker right now.',
    };
    final primaryActionLabel = switch (nextAction) {
      'Resolve return' => 'Raise issue',
      'Supplier follow-up' => 'Supplier support',
      'Unblock delayed order' => 'Supplier support',
      'Contact buyer' => 'Message buyer',
      'Track payout' => 'Open payouts',
      'Track fulfillment' => 'Supplier support',
      _ => 'Open details',
    };
    final riskSummary = <String>[
      if (needsBuyerContact) 'buyer follow-up',
      if (delayed) 'delay',
      if (unpaid) 'payout pending',
      if (_hasActivePayoutDispute(order, payoutDispute)) 'payout dispute',
      if (_hasActiveIssue(order, issueReport))
        issueReport == null
            ? 'supplier issue'
            : issueReport.issueType.toLowerCase(),
      if (order.status == 8) 'return',
    ];
    return _OrderExecutionProfile(
      delivered: delivered,
      delayed: delayed,
      unpaid: unpaid,
      profitable: profitable,
      highProfit: highProfit,
      needsBuyerContact: needsBuyerContact,
      atRisk: atRisk,
      nextActionLabel: nextAction,
      nextActionReason: nextReason,
      primaryActionLabel: primaryActionLabel,
      riskSummary: riskSummary.isEmpty ? 'healthy' : riskSummary.join(' • '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supplierName = context
        .read<StorefrontCubit>()
        .state
        .siteDetails
        ?.title
        ?.trim();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Orders',
        icon: HugeIcons.strokeRoundedInvoice03,
        showBackButton: true,
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final queueOrders = _applyQueue(state.orders);
          return RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _QueueTabs(
                  selected: _selectedTab,
                  onSelected: (tab) => setState(() {
                    _selectedTab = tab;
                  }),
                ),
                const SizedBox(height: 16),
                _OrderQueueOverviewCard(
                  tab: _selectedTab,
                  count: queueOrders.length,
                ),
                const SizedBox(height: 16),
                FutureBuilder<SupplierTrustProfile?>(
                  future: _supplierTrustFuture,
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    if (profile == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        _SupplierQueueSignalCard(
                          profile: profile,
                          tab: _selectedTab,
                          visibleOrders: queueOrders.length,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                if (state.loading && state.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_customerId == 0)
                  const _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedLogin02,
                    title: 'Sign in to view orders',
                  )
                else if (state.error != null)
                  _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedReceiptDollar,
                    title: state.error!.title,
                  )
                else if (queueOrders.isEmpty)
                  const _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedPackage01,
                    title: 'No orders in this queue',
                  )
                else
                  ...queueOrders.map(
                    (order) {
                      final profile = _executionProfile(order);
                      final issueReport = _issueReportFor(order);
                      final payoutDispute = _payoutDisputeFor(order);
                      return _OrderQueueCard(
                      order: order,
                      issueReport: issueReport,
                      payoutDispute: payoutDispute,
                      supplierName: (supplierName?.isNotEmpty ?? false)
                          ? supplierName!
                          : 'Active supplier',
                      cashState: _queueCashState(order, payoutDispute),
                      payoutStatus: _payoutStatus(order),
                      fulfillmentStatus: _fulfillmentStatus(order),
                      nextBestActionReason: profile.nextActionReason,
                      delayed: profile.delayed,
                      profitable: profile.profitable,
                      atRisk: profile.atRisk,
                      riskSummary: profile.riskSummary,
                      primaryActionLabel: profile.primaryActionLabel,
                      isBusy:
                          state.actionSubmitting &&
                          state.actionOrderId == order.id,
                      onOpen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<OrdersCubit>(),
                              child: OrderDetailsScreen(
                                siteId: StoreScope.activeSiteId(context),
                                order: order,
                              ),
                            ),
                          ),
                        );
                      },
                      onCopyId: () => _copyOrderId(order),
                      onMessageBuyer: () => _messageBuyer(order),
                      onSupplierSupport: () => _messageSupplierSupport(order),
                      onPrimaryAction: () {
                        switch (profile.primaryActionLabel) {
                          case 'Message buyer':
                            _messageBuyer(order);
                          case 'Supplier support':
                            _messageSupplierSupport(order);
                          case 'Raise issue':
                            _raiseIssue(order);
                          case 'Open payouts':
                            AppRouter.goToPayouts(context);
                          default:
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<OrdersCubit>(),
                                  child: OrderDetailsScreen(
                                    siteId: StoreScope.activeSiteId(context),
                                    order: order,
                                  ),
                                ),
                              ),
                            );
                        }
                      },
                    );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QueueTabs extends StatelessWidget {
  const _QueueTabs({required this.selected, required this.onSelected});

  final _OrderQueueTab selected;
  final ValueChanged<_OrderQueueTab> onSelected;

  static const Map<_OrderQueueTab, String> labels = <_OrderQueueTab, String>{
    _OrderQueueTab.needsAction: 'Needs action',
    _OrderQueueTab.awaitingBuyerConfirmation: 'Awaiting buyer',
    _OrderQueueTab.sentToSupplier: 'Sent',
    _OrderQueueTab.fulfillmentInProgress: 'In delivery',
    _OrderQueueTab.delivered: 'Delivered',
    _OrderQueueTab.atRisk: 'At risk',
    _OrderQueueTab.returnIssue: 'Issues',
    _OrderQueueTab.payoutPending: 'Payouts',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: selected == entry.key,
                  onSelected: (_) => onSelected(entry.key),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _OrderQueueOverviewCard extends StatelessWidget {
  const _OrderQueueOverviewCard({
    required this.tab,
    required this.count,
  });

  final _OrderQueueTab tab;
  final int count;

  String get _title {
    switch (tab) {
      case _OrderQueueTab.needsAction:
        return 'Orders that need your move';
      case _OrderQueueTab.awaitingBuyerConfirmation:
        return 'Buyer follow-up queue';
      case _OrderQueueTab.sentToSupplier:
        return 'Already sent to suppliers';
      case _OrderQueueTab.fulfillmentInProgress:
        return 'Orders in fulfilment';
      case _OrderQueueTab.delivered:
        return 'Delivered orders';
      case _OrderQueueTab.atRisk:
        return 'Orders at risk';
      case _OrderQueueTab.returnIssue:
        return 'Issues and returns';
      case _OrderQueueTab.payoutPending:
        return 'Waiting for payout';
    }
  }

  String get _subtitle {
    switch (tab) {
      case _OrderQueueTab.needsAction:
        return 'Start from the first order and clear the blocker.';
      case _OrderQueueTab.awaitingBuyerConfirmation:
        return 'Message buyers before supplier dispatch becomes risky.';
      case _OrderQueueTab.sentToSupplier:
        return 'Watch placement and confirm supplier movement.';
      case _OrderQueueTab.fulfillmentInProgress:
        return 'Track progress and intervene if delays appear.';
      case _OrderQueueTab.delivered:
        return 'Delivered orders are useful for repeat sell and payout follow-up.';
      case _OrderQueueTab.atRisk:
        return 'These orders need tighter follow-up to protect profit.';
      case _OrderQueueTab.returnIssue:
        return 'Resolve issue flags quickly before payout gets delayed.';
      case _OrderQueueTab.payoutPending:
        return 'Delivered but not settled yet. Keep payout watch tight.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$count order${count == 1 ? '' : 's'} in this queue',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierQueueSignalCard extends StatelessWidget {
  const _SupplierQueueSignalCard({
    required this.profile,
    required this.tab,
    required this.visibleOrders,
  });

  final SupplierTrustProfile profile;
  final _OrderQueueTab tab;
  final int visibleOrders;

  String get _headline {
    switch (tab) {
      case _OrderQueueTab.atRisk:
      case _OrderQueueTab.returnIssue:
        return 'Escalation pressure is live';
      case _OrderQueueTab.payoutPending:
        return 'Batch readiness depends on supplier health';
      default:
        return 'Supplier lane for this queue';
    }
  }

  String get _subtitle {
    final delivery = formatTrustDays(profile.averageDeliveryDays);
    final issues = formatTrustPercent(profile.minimumIssueRate);
    switch (tab) {
      case _OrderQueueTab.atRisk:
      case _OrderQueueTab.returnIssue:
        return 'Use support quickly when issue floor is high or trust drops. This supplier is running at $issues issues and $delivery average delivery.';
      case _OrderQueueTab.payoutPending:
        return 'Delivered orders usually clear into payout batches cleanly when supplier issues stay low. Current issue floor: $issues.';
      default:
        return 'This queue is backed by a supplier running at $delivery average delivery with $issues minimum issue rate.';
    }
  }

  String get _queuePillLabel {
    switch (tab) {
      case _OrderQueueTab.payoutPending:
        return 'Payout watch';
      case _OrderQueueTab.atRisk:
      case _OrderQueueTab.returnIssue:
        return 'Escalate fast';
      default:
        return 'Execution lane';
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyleForScore(profile.score);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                      _headline,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColor.text,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(label: _queuePillLabel, tone: _OrderPillTone.info),
              _StatusPill(
                label: 'Visible $visibleOrders',
                tone: _OrderPillTone.neutral,
              ),
              _StatusPill(
                label: formatTrustDays(profile.averageDeliveryDays),
                tone: style.band == SupplierTrustBand.watchlist
                    ? _OrderPillTone.alert
                    : _OrderPillTone.good,
              ),
              _StatusPill(
                label: 'Issue ${formatTrustPercent(profile.minimumIssueRate)}',
                tone: (profile.minimumIssueRate ?? 100) <= 3
                    ? _OrderPillTone.good
                    : _OrderPillTone.alert,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderQueueCard extends StatelessWidget {
  const _OrderQueueCard({
    required this.order,
    required this.issueReport,
    required this.payoutDispute,
    required this.supplierName,
    required this.cashState,
    required this.payoutStatus,
    required this.fulfillmentStatus,
    required this.nextBestActionReason,
    required this.delayed,
    required this.profitable,
    required this.atRisk,
    required this.riskSummary,
    required this.primaryActionLabel,
    required this.isBusy,
    required this.onOpen,
    required this.onCopyId,
    required this.onMessageBuyer,
    required this.onSupplierSupport,
    required this.onPrimaryAction,
  });

  final OrderHistoryResModelProfile order;
  final OrderIssueReport? issueReport;
  final PayoutDisputeEntry? payoutDispute;
  final String supplierName;
  final String cashState;
  final String payoutStatus;
  final String fulfillmentStatus;
  final String nextBestActionReason;
  final bool delayed;
  final bool profitable;
  final bool atRisk;
  final String riskSummary;
  final String primaryActionLabel;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback onCopyId;
  final VoidCallback onMessageBuyer;
  final VoidCallback onSupplierSupport;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (order.customerName ?? 'Buyer order').trim(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.orderId ?? 'Order'} • $supplierName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (issueReport != null || order.supportIssue)
                      _StatusPill(
                        label: issueReport == null
                            ? 'Issue flagged'
                            : issueReport!.status.trim().toLowerCase() == 'closed'
                                ? 'Issue closed'
                                : issueReport!.issueType,
                        tone: _OrderPillTone.alert,
                      ),
                    if (payoutDispute != null)
                      _StatusPill(
                        label: payoutDispute!.status.trim().toLowerCase() ==
                                'resolved'
                            ? 'Payout resolved'
                            : 'Payout dispute',
                        tone: _OrderPillTone.alert,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  label: profitable ? 'Profitable' : 'Low margin',
                  value: _currency(order.profit),
                  tone: profitable ? _OrderPillTone.good : _OrderPillTone.alert,
                ),
                _MetricPill(label: 'Sell', value: _currency(order.total)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  label: cashState,
                  tone: cashState == 'Paid out'
                      ? _OrderPillTone.good
                      : cashState == 'Dispute hold'
                          ? _OrderPillTone.alert
                          : _OrderPillTone.info,
                ),
                _StatusPill(label: payoutStatus),
                _StatusPill(
                  label: fulfillmentStatus,
                  tone: _OrderPillTone.info,
                ),
                if (delayed)
                  const _StatusPill(
                    label: 'Delayed',
                    tone: _OrderPillTone.alert,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              issueReport != null
                  ? '${issueReport!.issueType} • ${formatDateTime(issueReport!.updatedAt)}'
                  : payoutDispute != null
                      ? '${payoutDispute!.reason} • ${formatDateTime(payoutDispute!.updatedAt ?? payoutDispute!.createdAt)}'
                      : (atRisk ? riskSummary : nextBestActionReason),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: issueReport != null || payoutDispute != null || atRisk
                    ? AppColor.alert
                    : AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((order.customerAddress?.trim().isNotEmpty ?? false) ||
                (order.customerPhone?.toString().isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${order.customerAddress?.trim() ?? ''}${(order.customerPhone?.toString().isNotEmpty ?? false) ? ' • ${order.customerPhone}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onPrimaryAction,
                icon: AppHugeIcon(
                  _primaryActionIcon(primaryActionLabel),
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(primaryActionLabel),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChipButton(
                  label: 'Copy ID',
                  icon: HugeIcons.strokeRoundedReload,
                  onTap: onCopyId,
                  isBusy: false,
                ),
                _ActionChipButton(
                  label: 'Buyer',
                  icon: HugeIcons.strokeRoundedMessage02,
                  onTap: onMessageBuyer,
                ),
                _ActionChipButton(
                  label: 'Support',
                  icon: HugeIcons.strokeRoundedHelpCircle,
                  onTap: onSupplierSupport,
                  isBusy: isBusy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
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

enum _OrderPillTone { neutral, info, good, alert }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.tone = _OrderPillTone.neutral});

  final String label;
  final _OrderPillTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _OrderPillTone.neutral => AppColor.primary,
      _OrderPillTone.info => AppColor.info,
      _OrderPillTone.good => AppColor.green,
      _OrderPillTone.alert => AppColor.alert,
    };
    final background = switch (tone) {
      _OrderPillTone.neutral => AppColor.safe1,
      _OrderPillTone.info => AppColor.infoLight,
      _OrderPillTone.good => AppColor.safe1,
      _OrderPillTone.alert => AppColor.alertLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.tone = _OrderPillTone.neutral,
  });

  final String label;
  final String value;
  final _OrderPillTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: switch (tone) {
          _OrderPillTone.neutral => AppColor.safe1,
          _OrderPillTone.info => AppColor.infoLight,
          _OrderPillTone.good => AppColor.safe1,
          _OrderPillTone.alert => AppColor.alertLight,
        },
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(
            color: tone == _OrderPillTone.alert ? AppColor.alert : AppColor.neutral2,
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(
                color: tone == _OrderPillTone.good
                    ? AppColor.green
                    : tone == _OrderPillTone.alert
                    ? AppColor.alert
                    : AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({
    required this.icon,
    required this.title,
  });

  final List<List<dynamic>> icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        children: [
          AppHugeIcon(icon, size: 28, color: AppColor.primary),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

String _currency(num? value) => '৳ ${(value ?? 0).toStringAsFixed(0)}';

List<List<dynamic>> _primaryActionIcon(String label) {
  switch (label) {
    case 'Message buyer':
      return HugeIcons.strokeRoundedMessage02;
    case 'Supplier support':
      return HugeIcons.strokeRoundedHelpCircle;
    case 'Raise issue':
      return HugeIcons.strokeRoundedAlert02;
    case 'Open payouts':
      return HugeIcons.strokeRoundedWallet02;
    default:
      return HugeIcons.strokeRoundedArrowRight01;
  }
}

class _OrderExecutionProfile {
  const _OrderExecutionProfile({
    required this.delivered,
    required this.delayed,
    required this.unpaid,
    required this.profitable,
    required this.highProfit,
    required this.needsBuyerContact,
    required this.atRisk,
    required this.nextActionLabel,
    required this.nextActionReason,
    required this.primaryActionLabel,
    required this.riskSummary,
  });

  final bool delivered;
  final bool delayed;
  final bool unpaid;
  final bool profitable;
  final bool highProfit;
  final bool needsBuyerContact;
  final bool atRisk;
  final String nextActionLabel;
  final String nextActionReason;
  final String primaryActionLabel;
  final String riskSummary;
}
