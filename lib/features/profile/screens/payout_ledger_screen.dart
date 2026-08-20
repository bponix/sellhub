import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/payout_adjustment_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_batch_entry.dart';
import 'package:sellhub/features/profile/data/model/payout_dispute_entry.dart';
import 'package:sellhub/features/profile/data/model/reseller_payout_readiness.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class PayoutLedgerScreen extends StatefulWidget {
  const PayoutLedgerScreen({super.key});

  @override
  State<PayoutLedgerScreen> createState() => _PayoutLedgerScreenState();
}

enum _LedgerFilter {
  all,
  locked,
  processing,
  payable,
  released,
  paid,
  adjusted,
  disputed,
}

class _PayoutLedgerScreenState extends State<PayoutLedgerScreen> {
  late Future<_PayoutLedgerData> _future;
  _LedgerFilter _filter = _LedgerFilter.all;
  DateTimeRange? _dateRange;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _loadData();
  }

  Future<_PayoutLedgerData> _loadData() async {
    final repo = di.sl<ProfileRepository>();
    final siteId = StoreScope.activeSiteId(context);
    final customerId = await LocalStorage.getCustomerID() ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;

    final customerFuture = userId > 0
        ? repo.fetchSelfStoreCustomer(userId, siteId)
        : Future<SelfStoreCustomerRes?>.value(null);
    final ordersFuture = customerId > 0
        ? repo.fetchOrderHistory(siteId, customerId)
        : Future<List<OrderHistoryResModelProfile>>.value(
            const <OrderHistoryResModelProfile>[],
          );
    final profileFuture = customerId > 0
        ? repo.fetchProfileDetails(customerId)!
        : Future<ProfileResModel?>.value(null);
    final batchesFuture = userId > 0
        ? repo.fetchPayoutBatches(userId: userId, siteId: siteId)
        : Future<List<PayoutBatchEntry>>.value(const <PayoutBatchEntry>[]);
    final adjustmentsFuture = userId > 0
        ? repo.fetchPayoutAdjustments(userId: userId, siteId: siteId)
        : Future<List<PayoutAdjustmentEntry>>.value(
            const <PayoutAdjustmentEntry>[],
          );
    final disputesFuture = userId > 0
        ? repo.fetchPayoutDisputes(userId: userId, siteId: siteId)
        : Future<List<PayoutDisputeEntry>>.value(const <PayoutDisputeEntry>[]);
    final readinessFuture = userId > 0
        ? repo
              .fetchPayoutReadiness(siteId: siteId)
              .then<ResellerPayoutReadiness?>((value) => value)
              .catchError((_) => null)
        : Future<ResellerPayoutReadiness?>.value(null);

    final results = await Future.wait<dynamic>([
      customerFuture,
      ordersFuture,
      profileFuture,
      batchesFuture,
      adjustmentsFuture,
      disputesFuture,
      readinessFuture,
    ]);

    final orders = (results[1] as List<OrderHistoryResModelProfile>).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime(2000)).compareTo(
          a.updatedAt ?? DateTime(2000),
        ),
      );

    return _PayoutLedgerData(
      siteId: siteId,
      userId: userId,
      customerId: customerId,
      customer: results[0] as SelfStoreCustomerRes?,
      orders: orders,
      profile: results[2] as ProfileResModel?,
      batches: results[3] as List<PayoutBatchEntry>,
      adjustments: results[4] as List<PayoutAdjustmentEntry>,
      disputes: results[5] as List<PayoutDisputeEntry>,
      readiness: results[6] as ResellerPayoutReadiness?,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _requestPayout(_PayoutLedgerData data) async {
    final readiness = data.readiness;
    if (readiness == null || !readiness.canWithdraw) return;
    final amountController = TextEditingController(
      text: readiness.withdrawableAmount.toStringAsFixed(0),
    );
    final noteController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Request withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                helperText:
                    'Available ${_currency(readiness.withdrawableAmount)}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional payout reference',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Request'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) {
      amountController.dispose();
      noteController.dispose();
      return;
    }
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final note = noteController.text.trim();
    amountController.dispose();
    noteController.dispose();
    try {
      await di.sl<ProfileRepository>().createPayoutRequest(
        userId: data.userId,
        siteId: data.siteId,
        amount: amount,
        note: note,
        operationKey:
            'sellhub-payout:${data.siteId}:${data.userId}:${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request sent to Store.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
      helpText: 'Filter payout dates',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _dateRange = picked;
    });
  }

  Future<void> _shareLedger(
    _LedgerSummary summary,
    ResellerPayoutReadiness? readiness,
  ) async {
    final cashState = _summaryCashStateLabel(summary);
    final nextMove = _payoutPromise(summary);
    final channelStatus = _hasConfiguredPayoutChannel(summary)
        ? 'Ready'
        : 'Setup needed';
    final text = StringBuffer()
      ..writeln('SellHub payout readiness')
      ..writeln('Cash state: $cashState')
      ..writeln('Next move: $nextMove')
      ..writeln('Channel status: $channelStatus')
      ..writeln('Total earned: ${_currency(summary.totalEarned)}')
      ..writeln(
        'Withdrawable: ${_currency(readiness?.withdrawableAmount ?? summary.payableNow)}',
      )
      ..writeln(
        'Pending payout: ${_currency(readiness?.pendingPayoutAmount ?? summary.processing)}',
      )
      ..writeln(
        'Paid out: ${_currency(readiness?.paidAmount ?? summary.paidOut)}',
      )
      ..writeln('Blocked: ${_currency(readiness?.blockedPayoutAmount ?? 0)}')
      ..writeln('Disputed: ${_currency(readiness?.disputedAmount ?? 0)}')
      ..writeln('Deductions: ${_currency(summary.deductions)}')
      ..writeln('Return adjustments: ${_currency(summary.returnAdjustments)}')
      ..writeln('Proof source: Store payout and reseller ledgers')
      ..writeln('Payout channel: ${summary.payoutChannel}')
      ..writeln(
        'Estimated next payout: ${summary.estimatedNextPayoutDate == null ? 'Shows after the first payable batch' : formatDateTime(summary.estimatedNextPayoutDate)}',
      );
    await Share.share(text.toString(), subject: 'SellHub payout readiness');
  }

  Future<void> _reportMismatch(
    _PayoutLedgerData data,
    _PayoutOrderRowData row,
  ) async {
    final controller = TextEditingController(
      text: row.adjustments.isNotEmpty
          ? 'Please verify ${row.adjustments.first.label.toLowerCase()} on this order.'
          : '',
    );
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Create payout dispute'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe the payout issue for Store operations.',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Submit dispute'),
            ),
          ],
        );
      },
    );
    if (!mounted || note == null) return;
    final sourceOrder = data.orders
        .cast<OrderHistoryResModelProfile?>()
        .firstWhere(
          (order) => order?.orderId == row.orderId,
          orElse: () => null,
        );
    final numericOrderId = sourceOrder?.id ?? 0;
    if (numericOrderId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store order identity is unavailable.')),
      );
      return;
    }
    final repo = di.sl<ProfileRepository>();
    await repo.reportPayoutDispute(
      userId: data.userId,
      siteId: data.siteId,
      orderId: numericOrderId,
      batchId: row.batch?.id,
      reason: 'Payout mismatch',
      note: note,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payout dispute submitted for ${row.orderId}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _refresh();
  }

  bool _matchesDate(DateTime? date) {
    if (_dateRange == null) return true;
    if (date == null) return false;
    final start = DateTime(
      _dateRange!.start.year,
      _dateRange!.start.month,
      _dateRange!.start.day,
    );
    final end = DateTime(
      _dateRange!.end.year,
      _dateRange!.end.month,
      _dateRange!.end.day,
      23,
      59,
      59,
    );
    return !date.isBefore(start) && !date.isAfter(end);
  }

  bool _matchesFilter(_PayoutOrderRowData row) {
    switch (_filter) {
      case _LedgerFilter.all:
        return true;
      case _LedgerFilter.locked:
        return row.state == _PayoutState.locked;
      case _LedgerFilter.processing:
        return row.state == _PayoutState.processing;
      case _LedgerFilter.payable:
        return row.state == _PayoutState.payable;
      case _LedgerFilter.released:
        return row.state == _PayoutState.released;
      case _LedgerFilter.paid:
        return row.state == _PayoutState.paid;
      case _LedgerFilter.adjusted:
        return row.state == _PayoutState.adjusted;
      case _LedgerFilter.disputed:
        return row.dispute != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Payout Ledger',
        icon: HugeIcons.strokeRoundedWallet02,
        showBackButton: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_PayoutLedgerData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _LedgerEmptyState(
                    icon: HugeIcons.strokeRoundedAlert02,
                    title: 'Unable to load payout ledger',
                    subtitle: 'Pull to refresh and try again.',
                  ),
                ],
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _LedgerEmptyState(
                    icon: HugeIcons.strokeRoundedWallet02,
                    title: 'First payout starts here',
                    subtitle:
                        'Delivered orders will appear here as payout-ready cash.',
                  ),
                ],
              );
            }

            final rows = data.buildRows();
            final filteredRows = rows
                .where(
                  (row) => _matchesFilter(row) && _matchesDate(row.sortDate),
                )
                .toList(growable: false);
            final summary = _LedgerSummary.fromRows(
              rows: rows,
              payoutChannel: _payoutAccount(data.customer, data.profile),
              batches: data.batches,
              adjustments: data.adjustments,
            );
            final filteredBatches = data.batches
                .where(
                  (batch) => _matchesDate(
                    batch.paidAt ?? batch.releasedAt ?? batch.createdAt,
                  ),
                )
                .toList(growable: false);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _PayoutHero(
                  summary: summary,
                  onShare: () => _shareLedger(summary, data.readiness),
                  onOpenPayoutSetup: () => AppRouter.goToProfile(context),
                ),
                const SizedBox(height: 16),
                _PayoutReadinessCard(
                  readiness: data.readiness,
                  onRequest: data.readiness?.canWithdraw == true
                      ? () => _requestPayout(data)
                      : null,
                ),
                const SizedBox(height: 16),
                _PayoutOperatorCard(summary: summary),
                const SizedBox(height: 16),
                _PayoutPromiseTimelineCard(summary: summary),
                const SizedBox(height: 16),
                _LedgerControls(
                  selected: _filter,
                  rangeLabel: _dateRange == null
                      ? 'All dates'
                      : '${formatDateTime(_dateRange!.start)} - ${formatDateTime(_dateRange!.end)}',
                  onSelect: (filter) => setState(() => _filter = filter),
                  onPickDateRange: _pickDateRange,
                  onClearDateRange: _dateRange == null
                      ? null
                      : () => setState(() => _dateRange = null),
                ),
                const SizedBox(height: 16),
                const _LedgerLead(
                  title: 'Order payout rows',
                  subtitle: 'Margin, payout state, and blockers per order.',
                ),
                const SizedBox(height: 12),
                if (filteredRows.isEmpty)
                  const _LedgerEmptyState(
                    icon: HugeIcons.strokeRoundedWalletAdd01,
                    title: 'Payout rows appear after delivery',
                    subtitle:
                        'Try another state filter or clear the date range to bring delivered earning rows back.',
                  )
                else
                  ...filteredRows.map(
                    (row) => _LedgerOrderRow(
                      row: row,
                      onCopyOrderId: () async {
                        await Clipboard.setData(
                          ClipboardData(text: row.orderId),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order ID copied'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onReportMismatch: () => _reportMismatch(data, row),
                    ),
                  ),
                const SizedBox(height: 16),
                const _LedgerLead(
                  title: 'Payout batch history',
                  subtitle: 'Released and paid batches.',
                ),
                const SizedBox(height: 12),
                if (filteredBatches.isEmpty)
                  const _LedgerEmptyState(
                    icon: HugeIcons.strokeRoundedWalletDone02,
                    title: 'No payout batches in this view',
                    subtitle:
                        'Completed and released payout batches will appear here with batch IDs and transfer references.',
                  )
                else
                  ...filteredBatches.map(
                    (entry) => _PayoutHistoryCard(entry: entry),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _payoutAccount(
    SelfStoreCustomerRes? customer,
    ProfileResModel? profile,
  ) {
    final title =
        customer?.paymentTitle?.trim() ?? profile?.paymentTitle?.trim() ?? '';
    final number =
        customer?.paymentNo?.trim() ?? profile?.paymentNo?.trim() ?? '';
    if (title.isEmpty && number.isEmpty) {
      return 'Add a payout channel before the first release';
    }
    if (title.isEmpty) return number;
    if (number.isEmpty) return title;
    return '$title • $number';
  }
}

class _PayoutLedgerData {
  const _PayoutLedgerData({
    required this.siteId,
    required this.userId,
    required this.customerId,
    required this.customer,
    required this.profile,
    required this.orders,
    required this.batches,
    required this.adjustments,
    required this.disputes,
    required this.readiness,
  });

  final int siteId;
  final int userId;
  final int customerId;
  final SelfStoreCustomerRes? customer;
  final ProfileResModel? profile;
  final List<OrderHistoryResModelProfile> orders;
  final List<PayoutBatchEntry> batches;
  final List<PayoutAdjustmentEntry> adjustments;
  final List<PayoutDisputeEntry> disputes;
  final ResellerPayoutReadiness? readiness;

  List<_PayoutOrderRowData> buildRows() {
    return orders
        .map((order) {
          final orderId = order.orderId ?? 'Order';
          final batch = batches.cast<PayoutBatchEntry?>().firstWhere(
            (item) => item?.orderIds.contains(orderId) == true,
            orElse: () => null,
          );
          final orderAdjustments = adjustments
              .where((item) => item.orderId == orderId)
              .toList(growable: false);
          final dispute = disputes.cast<PayoutDisputeEntry?>().firstWhere(
            (item) =>
                item?.orderId == orderId || item?.orderId == '${order.id ?? 0}',
            orElse: () => null,
          );
          return _PayoutOrderRowData.fromOrder(
            order,
            batch: batch,
            adjustments: orderAdjustments,
            dispute: dispute,
          );
        })
        .toList(growable: false)
      ..sort(
        (a, b) => (b.sortDate ?? DateTime(2000)).compareTo(
          a.sortDate ?? DateTime(2000),
        ),
      );
  }
}

class _PayoutReadinessCard extends StatelessWidget {
  const _PayoutReadinessCard({required this.readiness, this.onRequest});

  final ResellerPayoutReadiness? readiness;
  final VoidCallback? onRequest;

  static const Map<String, String> _labels = <String, String>{
    'pending': 'Pending',
    'withdrawable': 'Withdrawable',
    'pending_payout': 'Pending payout',
    'paid': 'Paid',
    'requested_payout': 'Requested',
    'processing_payout': 'Processing',
    'settled_payout': 'Settled',
    'blocked_payout': 'Blocked',
    'disputed': 'Disputed',
    'reversed': 'Reversed',
    'proof_needed': 'Proof needed',
  };

  @override
  Widget build(BuildContext context) {
    final value = readiness;
    if (value == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xfffff8e5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xffffdf8a)),
        ),
        child: const Row(
          children: [
            AppHugeIcon(HugeIcons.strokeRoundedAlert02, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Store payout proof is temporarily unavailable. Refresh before requesting money.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }
    final buckets = value.buckets.isNotEmpty
        ? value.buckets
        : <ResellerPayoutBucket>[
            ResellerPayoutBucket(key: 'pending', amount: value.pendingAmount),
            ResellerPayoutBucket(
              key: 'withdrawable',
              amount: value.withdrawableAmount,
            ),
            ResellerPayoutBucket(
              key: 'pending_payout',
              amount: value.pendingPayoutAmount,
            ),
            ResellerPayoutBucket(key: 'paid', amount: value.paidAmount),
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value.canWithdraw
                      ? const Color(0xffe9f8ee)
                      : AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AppHugeIcon(
                  value.canWithdraw
                      ? HugeIcons.strokeRoundedWalletDone02
                      : HugeIcons.strokeRoundedWallet02,
                  size: 21,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STORE PAYOUT PROOF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColor.neutral2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.primaryAction,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.canWithdraw
                          ? 'Verified withdrawable profit is ready.'
                          : 'Pending, blocked, disputed, reversed, and proof-needed money stays separated.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buckets
                .take(8)
                .map(
                  (bucket) => Container(
                    width: 142,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _labels[bucket.key] ?? bucket.key,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currency(bucket.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            '${value.openPayoutCount} open request${value.openPayoutCount == 1 ? '' : 's'} · ${value.blockedPayoutCount} blocked',
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRequest != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRequest,
                icon: const AppHugeIcon(
                  HugeIcons.strokeRoundedMoneySend02,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text('Request withdrawal'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerSummary {
  const _LedgerSummary({
    required this.totalEarned,
    required this.payableNow,
    required this.processing,
    required this.released,
    required this.paidOut,
    required this.deductions,
    required this.returnAdjustments,
    required this.payoutChannel,
    required this.estimatedNextPayoutDate,
  });

  final double totalEarned;
  final double payableNow;
  final double processing;
  final double released;
  final double paidOut;
  final double deductions;
  final double returnAdjustments;
  final String payoutChannel;
  final DateTime? estimatedNextPayoutDate;

  factory _LedgerSummary.fromRows({
    required List<_PayoutOrderRowData> rows,
    required String payoutChannel,
    required List<PayoutBatchEntry> batches,
    required List<PayoutAdjustmentEntry> adjustments,
  }) {
    final totalEarned = rows
        .where((row) => row.state != _PayoutState.adjusted)
        .fold<double>(0, (sum, row) => sum + row.earnedMargin);
    final payableNow = rows
        .where((row) => row.state == _PayoutState.payable)
        .fold<double>(0, (sum, row) => sum + row.netAmount);
    final processing = rows
        .where(
          (row) =>
              row.state == _PayoutState.locked ||
              row.state == _PayoutState.processing,
        )
        .fold<double>(0, (sum, row) => sum + row.earnedMargin);
    final released = rows
        .where((row) => row.state == _PayoutState.released)
        .fold<double>(0, (sum, row) => sum + row.netAmount);
    final paidOut = rows
        .where((row) => row.state == _PayoutState.paid)
        .fold<double>(0, (sum, row) => sum + row.netAmount);
    final deductions = adjustments.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final returnAdjustments = adjustments
        .where((item) => item.type == 'return_adjustment')
        .fold<double>(0, (sum, row) => sum + row.amount);
    final estimatedNextPayoutDate =
        [
          ...batches
              .where(
                (batch) =>
                    batch.status == 'processing' || batch.status == 'scheduled',
              )
              .map((batch) => batch.estimatedSettlementDate),
          ...rows
              .where((row) => row.state == _PayoutState.payable)
              .map((row) => row.sortDate?.add(const Duration(days: 2))),
        ].whereType<DateTime>().fold<DateTime?>(
          null,
          (best, current) =>
              best == null || current.isBefore(best) ? current : best,
        );

    return _LedgerSummary(
      totalEarned: totalEarned,
      payableNow: payableNow,
      processing: processing,
      released: released,
      paidOut: paidOut,
      deductions: deductions,
      returnAdjustments: returnAdjustments,
      payoutChannel: payoutChannel,
      estimatedNextPayoutDate: estimatedNextPayoutDate,
    );
  }
}

enum _PayoutState { locked, processing, payable, released, paid, adjusted }

class _PayoutOrderRowData {
  const _PayoutOrderRowData({
    required this.orderId,
    required this.buyerName,
    required this.sortDate,
    required this.sellAmount,
    required this.baseAmount,
    required this.earnedMargin,
    required this.adjustmentTotal,
    required this.netAmount,
    required this.state,
    required this.stateLabel,
    required this.delayReason,
    required this.eligibleDate,
    required this.batchStatusLabel,
    required this.cashReleaseReason,
    required this.batch,
    required this.adjustments,
    required this.dispute,
  });

  final String orderId;
  final String buyerName;
  final DateTime? sortDate;
  final double sellAmount;
  final double baseAmount;
  final double earnedMargin;
  final double adjustmentTotal;
  final double netAmount;
  final _PayoutState state;
  final String stateLabel;
  final String delayReason;
  final DateTime? eligibleDate;
  final String batchStatusLabel;
  final String cashReleaseReason;
  final PayoutBatchEntry? batch;
  final List<PayoutAdjustmentEntry> adjustments;
  final PayoutDisputeEntry? dispute;

  factory _PayoutOrderRowData.fromOrder(
    OrderHistoryResModelProfile order, {
    required PayoutBatchEntry? batch,
    required List<PayoutAdjustmentEntry> adjustments,
    required PayoutDisputeEntry? dispute,
  }) {
    final status = order.status ?? 0;
    final returned = status == 8;
    final delivered = status >= 10 || status == 4;
    final adjustmentTotal = adjustments.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final netAmount = (((order.profit ?? 0) - adjustmentTotal).clamp(
      returned ? 0 : double.negativeInfinity,
      double.infinity,
    )).toDouble();
    if (returned) {
      return _PayoutOrderRowData(
        orderId: order.orderId ?? 'Order',
        buyerName: (order.customerName ?? 'Buyer').trim(),
        sortDate: order.updatedAt,
        sellAmount: (order.total ?? 0).toDouble(),
        baseAmount: (order.resellAmount ?? 0).toDouble(),
        earnedMargin: (order.profit ?? 0).toDouble(),
        adjustmentTotal: adjustmentTotal,
        netAmount: 0,
        state: _PayoutState.adjusted,
        stateLabel: 'Return adjusted',
        delayReason: adjustments.isEmpty
            ? 'Returned orders reverse reseller earnings until the issue is closed.'
            : adjustments.map((item) => item.note).join(' '),
        eligibleDate: null,
        batchStatusLabel: dispute != null ? 'Disputed' : 'Blocked',
        cashReleaseReason: dispute != null
            ? 'Payout is blocked by an active dispute.'
            : 'Returned orders do not enter payout batches until the issue is resolved.',
        batch: batch,
        adjustments: adjustments,
        dispute: dispute,
      );
    }
    if (batch?.status == 'paid') {
      return _PayoutOrderRowData(
        orderId: order.orderId ?? 'Order',
        buyerName: (order.customerName ?? 'Buyer').trim(),
        sortDate: batch?.paidAt ?? order.updatedAt,
        sellAmount: (order.total ?? 0).toDouble(),
        baseAmount: (order.resellAmount ?? 0).toDouble(),
        earnedMargin: (order.profit ?? 0).toDouble(),
        adjustmentTotal: adjustmentTotal,
        netAmount: netAmount,
        state: _PayoutState.paid,
        stateLabel: 'Paid out',
        delayReason: batch?.note.isNotEmpty == true
            ? batch!.note
            : 'Transferred to reseller payout channel.',
        eligibleDate: batch?.estimatedSettlementDate,
        batchStatusLabel: 'Paid in ${batch?.id ?? 'batch'}',
        cashReleaseReason: batch?.paidAt != null
            ? 'Paid via ${batch?.channel ?? 'configured payout channel'} on ${formatDateTime(batch!.paidAt)}.'
            : 'Transferred to reseller payout channel.',
        batch: batch,
        adjustments: adjustments,
        dispute: dispute,
      );
    }
    if (batch?.status == 'released') {
      return _PayoutOrderRowData(
        orderId: order.orderId ?? 'Order',
        buyerName: (order.customerName ?? 'Buyer').trim(),
        sortDate: batch?.releasedAt ?? order.updatedAt,
        sellAmount: (order.total ?? 0).toDouble(),
        baseAmount: (order.resellAmount ?? 0).toDouble(),
        earnedMargin: (order.profit ?? 0).toDouble(),
        adjustmentTotal: adjustmentTotal,
        netAmount: netAmount,
        state: _PayoutState.released,
        stateLabel: 'Released',
        delayReason:
            'Released by SellHub. Waiting for payout provider confirmation.',
        eligibleDate: batch?.estimatedSettlementDate,
        batchStatusLabel: 'Included in ${batch?.id ?? 'release batch'}',
        cashReleaseReason: batch?.note.isNotEmpty == true
            ? batch!.note
            : 'Released to the payout provider and waiting for wallet confirmation.',
        batch: batch,
        adjustments: adjustments,
        dispute: dispute,
      );
    }
    if (delivered) {
      final estimatedEligibleDate = order.updatedAt?.add(
        const Duration(days: 2),
      );
      return _PayoutOrderRowData(
        orderId: order.orderId ?? 'Order',
        buyerName: (order.customerName ?? 'Buyer').trim(),
        sortDate: order.updatedAt,
        sellAmount: (order.total ?? 0).toDouble(),
        baseAmount: (order.resellAmount ?? 0).toDouble(),
        earnedMargin: (order.profit ?? 0).toDouble(),
        adjustmentTotal: adjustmentTotal,
        netAmount: netAmount,
        state: _PayoutState.payable,
        stateLabel: 'Payable now',
        delayReason:
            'Delivery is complete. Order is ready for the next payout batch.',
        eligibleDate: batch?.estimatedSettlementDate ?? estimatedEligibleDate,
        batchStatusLabel: batch == null
            ? 'Waiting for batch inclusion'
            : 'Included in ${batch.id}',
        cashReleaseReason: batch == null
            ? 'The next scheduled release should assign this order.'
            : batch.note.isNotEmpty
            ? batch.note
            : 'Included in the next scheduled payout release.',
        batch: batch,
        adjustments: adjustments,
        dispute: dispute,
      );
    }
    if (status >= 4) {
      final estimatedEligibleDate = order.updatedAt?.add(
        const Duration(days: 2),
      );
      return _PayoutOrderRowData(
        orderId: order.orderId ?? 'Order',
        buyerName: (order.customerName ?? 'Buyer').trim(),
        sortDate: order.updatedAt,
        sellAmount: (order.total ?? 0).toDouble(),
        baseAmount: (order.resellAmount ?? 0).toDouble(),
        earnedMargin: (order.profit ?? 0).toDouble(),
        adjustmentTotal: adjustmentTotal,
        netAmount: netAmount,
        state: _PayoutState.processing,
        stateLabel: 'Processing',
        delayReason:
            'Order is still in fulfillment. Margin stays locked until delivery succeeds.',
        eligibleDate: estimatedEligibleDate,
        batchStatusLabel: 'Not eligible yet',
        cashReleaseReason:
            'Cash stays locked until delivery completes and the order clears the next payout window.',
        batch: batch,
        adjustments: adjustments,
        dispute: dispute,
      );
    }
    final estimatedEligibleDate = order.updatedAt?.add(const Duration(days: 4));
    return _PayoutOrderRowData(
      orderId: order.orderId ?? 'Order',
      buyerName: (order.customerName ?? 'Buyer').trim(),
      sortDate: order.updatedAt,
      sellAmount: (order.total ?? 0).toDouble(),
      baseAmount: (order.resellAmount ?? 0).toDouble(),
      earnedMargin: (order.profit ?? 0).toDouble(),
      adjustmentTotal: adjustmentTotal,
      netAmount: netAmount,
      state: _PayoutState.locked,
      stateLabel: 'Locked',
      delayReason:
          'Buyer confirmation and successful delivery must complete before payout starts.',
      eligibleDate: estimatedEligibleDate,
      batchStatusLabel: 'Pre-delivery lock',
      cashReleaseReason:
          'The order is still too early in the flow to enter any payout batch.',
      batch: batch,
      adjustments: adjustments,
      dispute: dispute,
    );
  }
}

class _PayoutHero extends StatelessWidget {
  const _PayoutHero({
    required this.summary,
    required this.onShare,
    required this.onOpenPayoutSetup,
  });

  final _LedgerSummary summary;
  final VoidCallback onShare;
  final VoidCallback onOpenPayoutSetup;

  @override
  Widget build(BuildContext context) {
    final promise = _payoutPromise(summary);
    final cashState = _summaryCashStateLabel(summary);
    final blockedReason = _blockedReason(summary);
    final releasedReason = _releasedReason(summary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LedgerIcon(icon: HugeIcons.strokeRoundedWallet02),
              const SizedBox(width: 12),
              const Expanded(
                child: _LedgerTitle(
                  title: 'Reseller payout snapshot',
                  subtitle:
                      'Local cash state, next payout move, and payout channel.',
                ),
              ),
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Share local ledger',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LedgerMetric(
                label: 'Payable now',
                value: _currency(summary.payableNow),
              ),
              _LedgerMetric(
                label: 'Processing',
                value: _currency(summary.processing),
              ),
              _LedgerMetric(
                label: 'Released',
                value: _currency(summary.released),
              ),
              _LedgerMetric(
                label: 'Paid out',
                value: _currency(summary.paidOut),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedAlert02,
                  label: 'Cash state',
                  value: cashState,
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedZap,
                  label: 'Next move',
                  value: promise,
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedWalletDone02,
                  label: 'Payout channel',
                  value: summary.payoutChannel,
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedDatabase,
                  label: 'Record mode',
                  value: 'Local MVP record',
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  label: 'Channel status',
                  value: _hasConfiguredPayoutChannel(summary)
                      ? 'Ready'
                      : 'Setup needed',
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  label: 'Next payout',
                  value: summary.estimatedNextPayoutDate == null
                      ? 'Shows after the first payable batch'
                      : formatDateTime(summary.estimatedNextPayoutDate),
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  label: 'Blocked by',
                  value: blockedReason,
                ),
                const SizedBox(height: 8),
                _ChannelRow(
                  icon: HugeIcons.strokeRoundedWallet05,
                  label: 'Released because',
                  value: releasedReason,
                ),
                if (!_hasConfiguredPayoutChannel(summary)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onOpenPayoutSetup,
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Set payout channel'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerControls extends StatelessWidget {
  const _LedgerControls({
    required this.selected,
    required this.rangeLabel,
    required this.onSelect,
    required this.onPickDateRange,
    required this.onClearDateRange,
  });

  final _LedgerFilter selected;
  final String rangeLabel;
  final ValueChanged<_LedgerFilter> onSelect;
  final VoidCallback onPickDateRange;
  final VoidCallback? onClearDateRange;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Filter payout rows',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _LedgerFilter.values
                .map(
                  (filter) => ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: selected == filter,
                    onSelected: (_) => onSelect(filter),
                    backgroundColor: AppColor.safe1,
                    selectedColor: AppColor.primarySoft,
                    side: const BorderSide(color: AppColor.safe),
                    labelStyle: TextStyle(
                      color: selected == filter
                          ? AppColor.primary
                          : AppColor.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onPickDateRange,
                icon: const Icon(Icons.date_range_rounded, size: 18),
                label: Text(rangeLabel),
              ),
              if (onClearDateRange != null)
                TextButton(
                  onPressed: onClearDateRange,
                  child: const Text('Clear date filter'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutOperatorCard extends StatelessWidget {
  const _PayoutOperatorCard({required this.summary});

  final _LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    final cashState = _summaryCashStateLabel(summary);
    final nextStep = summary.payableNow > 0
        ? 'Open payable rows and confirm the next payout batch.'
        : summary.processing > 0
        ? 'Track delivery completion. Profit is still locked in fulfilment.'
        : 'Keep selling and wait for the first payable batch.';
    final blocker = _blockedReason(summary);
    final released = _releasedReason(summary);
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
            'What matters now',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cashState,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextStep,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _MetaStrip(
            icon: HugeIcons.strokeRoundedLockPassword,
            label: 'Current blocker',
            value: blocker,
            tint: summary.processing > 0 ? AppColor.warning : AppColor.neutral2,
          ),
          const SizedBox(height: 8),
          _MetaStrip(
            icon: HugeIcons.strokeRoundedWallet05,
            label: 'Release state',
            value: released,
            tint: summary.released > 0 ? AppColor.primary : AppColor.neutral2,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerMetric(
                label: 'Payable',
                value: _currency(summary.payableNow),
              ),
              _LedgerMetric(
                label: 'Deductions',
                value: _currency(summary.deductions),
              ),
              _LedgerMetric(
                label: 'Returns',
                value: _currency(summary.returnAdjustments),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayoutPromiseTimelineCard extends StatelessWidget {
  const _PayoutPromiseTimelineCard({required this.summary});

  final _LedgerSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasPayable = summary.payableNow > 0;
    final hasProcessing = summary.processing > 0;
    final hasReleased = summary.released > 0;
    final blockedReason = _blockedReason(summary);
    final releasedReason = _releasedReason(summary);
    final timeline = <_PayoutPromiseStep>[
      _PayoutPromiseStep(
        title: 'Locked in fulfilment',
        subtitle: hasProcessing
            ? '${_currency(summary.processing)} is still waiting for delivery. $blockedReason'
            : 'The next delivery lock will appear here first.',
        active: hasProcessing,
      ),
      _PayoutPromiseStep(
        title: 'Payable for batch',
        subtitle: hasPayable
            ? '${_currency(summary.payableNow)} is ready for the next payout run.'
            : 'The first payable amount will appear here after delivery clears.',
        active: hasPayable,
      ),
      _PayoutPromiseStep(
        title: 'Released to channel',
        subtitle: hasReleased
            ? '${_currency(summary.released)} is already released to your payout method. $releasedReason'
            : 'The first released payout will appear here after the release run.',
        active: hasReleased,
      ),
    ];

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
            'Payout promise timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.estimatedNextPayoutDate == null
                ? 'Your next payout date will appear here once at least one delivered order becomes payable.'
                : 'Expected next payout window: ${formatDateTime(summary.estimatedNextPayoutDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...timeline.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: step.active ? AppColor.primary : AppColor.safe,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColor.text,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColor.neutral2,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutPromiseStep {
  const _PayoutPromiseStep({
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final String title;
  final String subtitle;
  final bool active;
}

class _LedgerLead extends StatelessWidget {
  const _LedgerLead({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LedgerIcon(icon: HugeIcons.strokeRoundedInvoice03),
        const SizedBox(width: 12),
        Expanded(
          child: _LedgerTitle(title: title, subtitle: subtitle),
        ),
      ],
    );
  }
}

class _LedgerOrderRow extends StatelessWidget {
  const _LedgerOrderRow({
    required this.row,
    required this.onCopyOrderId,
    required this.onReportMismatch,
  });

  final _PayoutOrderRowData row;
  final VoidCallback onCopyOrderId;
  final VoidCallback onReportMismatch;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      row.orderId,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${row.buyerName} • ${formatDateTime(row.sortDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _LedgerStatePill(state: row.state, label: row.stateLabel),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerMetric(
                label: 'Margin',
                value: _currency(row.earnedMargin),
              ),
              _LedgerMetric(label: 'Payout', value: _currency(row.netAmount)),
              if (row.adjustmentTotal > 0)
                _LedgerMetric(
                  label: 'Deductions',
                  value: _currency(row.adjustmentTotal),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _stateBackground(row.state),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _stateColor(row.state)),
            ),
            child: Text(
              row.delayReason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _stateColor(row.state),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerMetric(
                label: 'Cash state',
                value: _cashReadinessLabel(row),
              ),
              _LedgerMetric(label: 'Batch', value: row.batchStatusLabel),
            ],
          ),
          const SizedBox(height: 10),
          _MetaStrip(
            icon: HugeIcons.strokeRoundedWallet05,
            label: 'Cash release',
            value: row.cashReleaseReason,
            tint: _stateColor(row.state),
          ),
          if (row.batch != null ||
              row.dispute != null ||
              row.adjustments.isNotEmpty)
            const SizedBox(height: 12),
          if (row.batch != null)
            _MetaStrip(
              icon: HugeIcons.strokeRoundedWallet03,
              label: 'Batch',
              value:
                  '${row.batch!.id} • ${row.batch!.referenceId} • ${row.batch!.channel}',
            ),
          if (row.batch != null) const SizedBox(height: 8),
          if (row.dispute != null)
            _MetaStrip(
              icon: HugeIcons.strokeRoundedAlert02,
              label: 'Dispute',
              value:
                  '${_disputeStatusLabel(row.dispute!.status)} • ${row.dispute!.reason}',
              tint: AppColor.warning,
            ),
          if (row.dispute != null) const SizedBox(height: 8),
          if (row.dispute != null)
            _MetaStrip(
              icon: HugeIcons.strokeRoundedDatabase,
              label: 'Record mode',
              value: 'Local dispute record',
              tint: AppColor.warning,
            ),
          if (row.dispute != null) const SizedBox(height: 8),
          if (row.dispute != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LedgerMetric(
                  label: 'Dispute stage',
                  value: _disputeStatusLabel(row.dispute!.status),
                ),
                _LedgerMetric(
                  label: 'Updated',
                  value: formatDateTime(
                    row.dispute!.updatedAt ?? row.dispute!.createdAt,
                  ),
                ),
              ],
            ),
          if (row.dispute != null) const SizedBox(height: 10),
          if (row.dispute != null)
            _MetaStrip(
              icon: HugeIcons.strokeRoundedCustomerSupport,
              label: 'Dispute lifecycle',
              value: _disputeLifecycleHint(row.dispute!),
              tint: AppColor.warning,
            ),
          if (row.dispute != null) const SizedBox(height: 8),
          if (row.adjustments.isNotEmpty)
            _AdjustmentSummary(adjustments: row.adjustments),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCopyOrderId,
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy ID'),
              ),
              FilledButton.tonalIcon(
                onPressed: onReportMismatch,
                icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
                label: Text(
                  row.dispute == null ? 'Create dispute' : 'Update dispute',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _hasConfiguredPayoutChannel(_LedgerSummary summary) {
  return !summary.payoutChannel.toLowerCase().contains(
    'no payout channel configured',
  );
}

String _payoutPromise(_LedgerSummary summary) {
  if (_hasConfiguredPayoutChannel(summary) && summary.payableNow > 0) {
    return 'Ready for the next payout batch.';
  }
  if (summary.payableNow > 0) {
    return 'Add a payout channel to release payable earnings.';
  }
  if (summary.processing > 0) {
    return 'Current orders are still in delivery lock.';
  }
  if (summary.released > 0) {
    return 'Released payouts are waiting on wallet confirmation.';
  }
  return 'The first delivered order will set your next payout move here.';
}

String _blockedReason(_LedgerSummary summary) {
  if (summary.processing > 0) {
    return 'Delivered cash is still locked behind fulfilment completion and buyer acceptance.';
  }
  if (summary.payableNow > 0 && !_hasConfiguredPayoutChannel(summary)) {
    return 'A payout channel is missing, so payable earnings cannot be released yet.';
  }
  if (summary.returnAdjustments > 0) {
    return 'Returns and related adjustments are reducing what can move into payout.';
  }
  if (summary.deductions > 0) {
    return 'Fees and payout adjustments are trimming the release amount.';
  }
  return 'The next delivered order will set the first payout blocker here.';
}

String _releasedReason(_LedgerSummary summary) {
  if (summary.released > 0) {
    return 'SellHub has already released some earnings to the configured payout channel and is waiting on provider confirmation.';
  }
  if (summary.paidOut > 0) {
    return 'Earlier payout batches have already settled into the reseller payout channel.';
  }
  if (summary.payableNow > 0) {
    return 'Once the next payout batch runs, payable earnings should move into release.';
  }
  return 'Released cash will appear here after the first payout release runs.';
}

String _summaryCashStateLabel(_LedgerSummary summary) {
  if (summary.released > 0) {
    return 'Cash is in release transit';
  }
  if (summary.payableNow > 0 && !_hasConfiguredPayoutChannel(summary)) {
    return 'Cash is ready but channel setup is missing';
  }
  if (summary.payableNow > 0) {
    return 'Cash is ready for the next payout batch';
  }
  if (summary.processing > 0) {
    return 'Cash is still locked in fulfilment';
  }
  if (summary.paidOut > 0) {
    return 'Earlier cash already settled';
  }
  return 'Payout-ready cash will appear here after delivery clears';
}

String _cashReadinessLabel(_PayoutOrderRowData row) {
  switch (row.state) {
    case _PayoutState.locked:
      return 'Delivery lock';
    case _PayoutState.processing:
      return 'Clearing now';
    case _PayoutState.payable:
      return row.eligibleDate == null
          ? 'Ready for batch'
          : 'Ready ${formatDateTime(row.eligibleDate)}';
    case _PayoutState.released:
      return 'Released';
    case _PayoutState.paid:
      return 'Paid out';
    case _PayoutState.adjusted:
      return row.dispute == null ? 'Adjustment hold' : 'Dispute hold';
  }
}

String _disputeStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'open':
      return 'Open';
    case 'reviewing':
      return 'Under review';
    case 'resolved':
      return 'Resolved';
    case 'rejected':
      return 'Rejected';
    default:
      return status.trim().isEmpty ? 'Open' : status.trim();
  }
}

String _disputeLifecycleHint(PayoutDisputeEntry dispute) {
  final status = dispute.status.trim().toLowerCase();
  final updatedAt = dispute.updatedAt ?? dispute.createdAt;
  final updatedLabel = updatedAt == null
      ? ''
      : ' Last update ${formatDateTime(updatedAt)}.';
  switch (status) {
    case 'reviewing':
      return 'Support is checking the payout mismatch and batch math.$updatedLabel';
    case 'resolved':
      return 'The dispute has been resolved. Confirm the payout row matches the final release.$updatedLabel';
    case 'rejected':
      return 'Support closed the dispute without adjustment. Review the note and reopen only if evidence changed.$updatedLabel';
    case 'open':
    default:
      return 'The dispute is logged and waiting for support review.$updatedLabel';
  }
}

class _PayoutHistoryCard extends StatelessWidget {
  const _PayoutHistoryCard({required this.entry});

  final PayoutBatchEntry entry;

  @override
  Widget build(BuildContext context) {
    final state = _batchState(entry.status);
    final inclusionLabel = _batchInclusionLabel(entry);
    final releaseReason = _batchReleaseReason(entry);
    return Container(
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
                      entry.id,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColor.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.referenceId} • ${entry.channel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _LedgerStatePill(state: state, label: _batchLabel(entry.status)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LedgerMetric(
                label: 'Gross',
                value: _currency(entry.totalAmount),
              ),
              _LedgerMetric(
                label: 'Deduction',
                value: _currency(entry.deductionTotal),
              ),
              _LedgerMetric(label: 'Net', value: _currency(entry.netAmount)),
              _LedgerMetric(label: 'Orders', value: '${entry.orderIds.length}'),
              _LedgerMetric(
                label: 'Cash state',
                value: _batchCashStateLabel(entry),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetaStrip(
            icon: HugeIcons.strokeRoundedPackageProcess,
            label: 'Batch inclusion',
            value: inclusionLabel,
            tint: _stateColor(state),
          ),
          const SizedBox(height: 8),
          _MetaStrip(
            icon: HugeIcons.strokeRoundedWallet05,
            label: 'Release reason',
            value: releaseReason,
            tint: _stateColor(state),
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${formatDateTime(entry.createdAt)}'
            '${entry.releasedAt != null ? ' • Released ${formatDateTime(entry.releasedAt)}' : ''}'
            '${entry.paidAt != null ? ' • Paid ${formatDateTime(entry.paidAt)}' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _batchInclusionLabel(PayoutBatchEntry entry) {
  switch (entry.status.trim().toLowerCase()) {
    case 'paid':
      return 'Included and paid in ${entry.id}.';
    case 'released':
      return 'Included and released in ${entry.id}.';
    case 'scheduled':
      return 'Queued for the next payout run in ${entry.id}.';
    case 'processing':
    default:
      return entry.orderIds.isEmpty
          ? 'Waiting for batch assignment.'
          : 'Included in ${entry.id} and waiting for release.';
  }
}

String _batchReleaseReason(PayoutBatchEntry entry) {
  if (entry.note.trim().isNotEmpty) {
    return entry.note.trim();
  }
  switch (entry.status.trim().toLowerCase()) {
    case 'paid':
      return 'Cash moved through ${entry.channel} and provider confirmation is complete.';
    case 'released':
      return 'SellHub released the batch to ${entry.channel}, but provider confirmation is still pending.';
    case 'scheduled':
      return 'The batch is prepared and waiting for the scheduled payout window.';
    case 'processing':
    default:
      return 'Orders are still being gathered and cleared before release.';
  }
}

String _batchCashStateLabel(PayoutBatchEntry entry) {
  switch (entry.status.trim().toLowerCase()) {
    case 'paid':
      return 'Paid out';
    case 'released':
      return 'Released';
    case 'scheduled':
      return entry.estimatedSettlementDate == null
          ? 'Ready for payout'
          : 'Ready ${formatDateTime(entry.estimatedSettlementDate)}';
    case 'processing':
    default:
      return entry.orderIds.isEmpty ? 'Awaiting orders' : 'Clearing now';
  }
}

class _AdjustmentSummary extends StatelessWidget {
  const _AdjustmentSummary({required this.adjustments});

  final List<PayoutAdjustmentEntry> adjustments;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.alertLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.alert),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: adjustments
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${item.label}: ${_currency(item.amount)} • ${item.note}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.alert,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _MetaStrip extends StatelessWidget {
  const _MetaStrip({
    required this.icon,
    required this.label,
    required this.value,
    this.tint = AppColor.primary,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHugeIcon(icon, size: 16, color: tint),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LedgerMetric extends StatelessWidget {
  const _LedgerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHugeIcon(icon, size: 16, color: AppColor.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LedgerStatePill extends StatelessWidget {
  const _LedgerStatePill({required this.state, required this.label});

  final _PayoutState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _stateBackground(state),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _stateColor(state)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _stateColor(state),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LedgerIcon extends StatelessWidget {
  const _LedgerIcon({required this.icon});

  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
    );
  }
}

class _LedgerTitle extends StatelessWidget {
  const _LedgerTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColor.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _LedgerEmptyState extends StatelessWidget {
  const _LedgerEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

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
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColor.neutral2),
          ),
        ],
      ),
    );
  }
}

_PayoutState _batchState(String status) {
  switch (status) {
    case 'paid':
      return _PayoutState.paid;
    case 'released':
      return _PayoutState.released;
    default:
      return _PayoutState.processing;
  }
}

String _batchLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Paid out';
    case 'released':
      return 'Released';
    case 'scheduled':
      return 'Scheduled';
    default:
      return 'Processing';
  }
}

String _filterLabel(_LedgerFilter filter) {
  switch (filter) {
    case _LedgerFilter.all:
      return 'All';
    case _LedgerFilter.locked:
      return 'Locked';
    case _LedgerFilter.processing:
      return 'Processing';
    case _LedgerFilter.payable:
      return 'Payable';
    case _LedgerFilter.released:
      return 'Released';
    case _LedgerFilter.paid:
      return 'Paid';
    case _LedgerFilter.adjusted:
      return 'Adjusted';
    case _LedgerFilter.disputed:
      return 'Disputed';
  }
}

Color _stateColor(_PayoutState state) {
  switch (state) {
    case _PayoutState.locked:
      return AppColor.neutral2;
    case _PayoutState.processing:
      return AppColor.info;
    case _PayoutState.payable:
      return AppColor.primary;
    case _PayoutState.released:
      return AppColor.warning;
    case _PayoutState.paid:
      return AppColor.green;
    case _PayoutState.adjusted:
      return AppColor.alert;
  }
}

Color _stateBackground(_PayoutState state) {
  switch (state) {
    case _PayoutState.locked:
      return AppColor.safe1;
    case _PayoutState.processing:
      return AppColor.infoLight;
    case _PayoutState.payable:
      return AppColor.primarySoft;
    case _PayoutState.released:
      return AppColor.warningLight;
    case _PayoutState.paid:
      return AppColor.safe1;
    case _PayoutState.adjusted:
      return AppColor.alertLight;
  }
}

String _currency(num? value) => '৳ ${(value ?? 0).toStringAsFixed(0)}';
