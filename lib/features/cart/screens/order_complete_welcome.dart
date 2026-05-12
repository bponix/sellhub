import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/shell/presentation/cubit/store_shell_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderCompleteWelcome extends StatelessWidget {
  const OrderCompleteWelcome({super.key, required this.order});

  final OrderCreateRes order;

  static const Map<int, String> _statusNames = <int, String>{
    0: 'Processing',
    1: 'Placed',
    2: 'Confirmed',
    3: 'Packaging',
    4: 'Packed',
    5: 'Shipping',
    6: 'Review',
    7: 'Rejected',
    8: 'Returned',
    9: 'Canceled',
    10: 'Delivered',
  };

  String _nextActionTitle() {
    final status = order.status ?? 0;
    if (status >= 10 && order.isSettle != true) {
      return 'Review payout release';
    }
    if (status >= 4) {
      return 'Track fulfillment';
    }
    return 'Open the order queue';
  }

  String _nextActionDescription() {
    final status = order.status ?? 0;
    if (status >= 10 && order.isSettle != true) {
      return 'The order is delivered. Check payout timing and any adjustment status next.';
    }
    if (status >= 4) {
      return 'Supplier fulfillment is active. Open the queue to watch delays and buyer follow-up.';
    }
    return 'The order is created. Open the queue and keep the buyer updated on the next status change.';
  }

  String _nextActionLabel() {
    final status = order.status ?? 0;
    if (status >= 10 && order.isSettle != true) {
      return 'Open payouts';
    }
    return 'Open orders';
  }

  void _runNextAction(BuildContext context) {
    final status = order.status ?? 0;
    if (status >= 10 && order.isSettle != true) {
      AppRouter.goToPayouts(context);
      return;
    }
    AppRouter.goToOrders(context);
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = order.lines.fold<int>(
      0,
      (sum, line) => sum + (line.quantity ?? 0),
    );
    final total = order.total ?? 0;
    final statusLabel = _statusNames[order.status] ?? 'Pending';
    final orderLabel = (order.orderId ?? '').trim().isEmpty
        ? 'Invoice ready'
        : order.orderId!.trim();
    final customerName = (order.customerName ?? '').trim().isEmpty
        ? 'Customer'
        : order.customerName!.trim();
    final updatedLabel = order.updatedAt != null
        ? formatDateTime(order.updatedAt)
        : 'Just now';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Order created',
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _CompletionOverviewCard(
            total: total,
            itemCount: itemCount,
            orderLabel: orderLabel,
            statusLabel: statusLabel,
          ),
          const SizedBox(height: 16),
          _CompletionRouteStrip(
            routeLabel: _nextActionLabel(),
            statusLabel: statusLabel,
            updatedLabel: updatedLabel,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroPill(
                      label: statusLabel,
                      toneColor: AppColor.primary,
                      background: AppColor.primarySoft,
                    ),
                    _HeroPill(
                      label: orderLabel,
                      toneColor: AppColor.text,
                      background: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColor.safe1,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.safe),
                      ),
                      child: const AppHugeIcon(
                        HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: AppColor.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order created',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColor.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your order is in the queue and follow-up tracking has started.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColor.neutral2,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: 'Updated',
                        value: updatedLabel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(label: 'Buyer', value: customerName),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Builder(
              builder: (context) {
                final activeStore = context
                    .read<StoreContextCubit>()
                    .state
                    .activeStore;
                final canShare = activeStore != null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLead(
                      icon: HugeIcons.strokeRoundedInvoice03,
                      eyebrow: 'Invoice',
                      title: 'Order summary',
                    ),
                    const SizedBox(height: 12),
                    _InvoiceRow(label: 'Order ID', value: order.orderId ?? '-'),
                    _InvoiceRow(label: 'Customer', value: customerName),
                    _InvoiceRow(
                      label: 'Total',
                      value: '৳${convertToBengaliNumber(total)}',
                      emphasize: true,
                    ),
                    _InvoiceRow(label: 'Items', value: '$itemCount'),
                    _InvoiceRow(label: 'Status', value: statusLabel),
                    if (canShare) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final text =
                                SellHubShareLinkBuilder.buildOrderShareText(
                                  store: activeStore,
                                  order: order,
                                );
                            Share.share(text, subject: 'SellHub order context');
                          },
                          icon: const AppHugeIcon(
                            HugeIcons.strokeRoundedShare08,
                            size: 18,
                          ),
                          label: const Text('Share order'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _runNextAction(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColor.safe),
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(_nextActionLabel()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<StoreShellCubit>().setIndex(0);
                    AppRouter.goToHome(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDFF55A),
                    foregroundColor: AppColor.text,
                    elevation: 0,
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text(
                    'Keep selling',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionOverviewCard extends StatelessWidget {
  const _CompletionOverviewCard({
    required this.total,
    required this.itemCount,
    required this.orderLabel,
    required this.statusLabel,
  });

  final int total;
  final int itemCount;
  final String orderLabel;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _HeroPill(
            label: statusLabel,
            toneColor: AppColor.primary,
            background: AppColor.primarySoft,
          ),
          _HeroPill(
            label: orderLabel,
            toneColor: AppColor.text,
            background: Colors.white,
          ),
          _HeroPill(
            label: '৳${convertToBengaliNumber(total)}',
            toneColor: const Color(0xFF0E9F6E),
            background: const Color(0xFFEAF8F1),
          ),
          _HeroPill(
            label: '$itemCount item${itemCount == 1 ? '' : 's'}',
            toneColor: AppColor.text,
            background: AppColor.safe1,
          ),
        ],
      ),
    );
  }
}

class _CompletionRouteStrip extends StatelessWidget {
  const _CompletionRouteStrip({
    required this.routeLabel,
    required this.statusLabel,
    required this.updatedLabel,
  });

  final String routeLabel;
  final String statusLabel;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HeroPill(
          label: routeLabel,
          toneColor: AppColor.primary,
          background: AppColor.primarySoft,
        ),
        _HeroPill(
          label: statusLabel,
          toneColor: AppColor.text,
          background: AppColor.safe1,
        ),
        _HeroPill(
          label: updatedLabel,
          toneColor: AppColor.neutral2,
          background: Colors.white,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: child,
    );
  }
}

class _SectionLead extends StatelessWidget {
  const _SectionLead({
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
          width: 38,
          height: 38,
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
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: toneColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: emphasize ? AppColor.primary : AppColor.text,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
