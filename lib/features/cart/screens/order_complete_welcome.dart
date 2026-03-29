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

  static const List<_OrderStage> _stages = <_OrderStage>[
    _OrderStage('Placed', HugeIcons.strokeRoundedShoppingBag01),
    _OrderStage('Confirmed', HugeIcons.strokeRoundedCheckmarkCircle02),
    _OrderStage('Packed', HugeIcons.strokeRoundedPackageProcess),
    _OrderStage('Delivered', HugeIcons.strokeRoundedDeliveryTruck02),
  ];

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

  int _currentStageIndex() {
    final status = order.status ?? 0;
    if (status >= 10) return 3;
    if (status >= 4) return 2;
    if (status >= 2) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = order.lines.fold<int>(
      0,
      (sum, line) => sum + (line.quantity ?? 0),
    );
    final total = order.total ?? 0;
    final subtotal = order.netAmount ?? order.grossAmount ?? total;
    final deliveryCharge = order.logisticsCharge?.round() ?? 0;
    final discount = order.discount?.round() ?? 0;
    final statusLabel = _statusNames[order.status] ?? 'Pending';
    final orderLabel = (order.orderId ?? '').trim().isEmpty
        ? 'Invoice ready'
        : order.orderId!.trim();
    final customerName = (order.customerName ?? '').trim().isEmpty
        ? 'Customer'
        : order.customerName!.trim();
    final customerPhone = '${order.customerPhone ?? ''}'.trim().isEmpty
        ? 'Unavailable'
        : '${order.customerPhone ?? ''}'.trim();
    final customerAddress = (order.customerAddress ?? '').trim().isEmpty
        ? ((order.address ?? '').trim().isEmpty
              ? 'No address provided'
              : order.address!.trim())
        : order.customerAddress!.trim();
    final gatewayText = (order.gatewayText ?? '').trim().isEmpty
        ? 'Pending'
        : order.gatewayText!.trim();
    final deliveryText = (order.logisticsText ?? '').trim().isEmpty
        ? 'Standard'
        : order.logisticsText!.trim();
    final updatedLabel = order.updatedAt != null
        ? formatDateTime(order.updatedAt)
        : 'Just now';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Order placed',
        subtitle: 'Invoice and progress',
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
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
                            'Order confirmed',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColor.text,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your invoice is ready and progress tracking has started.',
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
                        label: 'Total',
                        value: '৳${convertToBengaliNumber(total)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(label: 'Items', value: '$itemCount'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(label: 'Updated', value: updatedLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLead(
                  icon: HugeIcons.strokeRoundedPackageProcess,
                  eyebrow: 'Live status',
                  title: 'Order progress',
                ),
                const SizedBox(height: 14),
                Row(
                  children: List.generate(_stages.length, (index) {
                    final step = _stages[index];
                    final isActive = index <= _currentStageIndex();
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
                          if (index != _stages.length - 1)
                            Container(
                              width: 18,
                              height: 2,
                              margin: const EdgeInsets.only(bottom: 28),
                              color: index < _currentStageIndex()
                                  ? AppColor.primary
                                  : AppColor.safe,
                            ),
                        ],
                      ),
                    );
                  }),
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
                  child: Text(
                    'Current stage: $statusLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLead(
                  icon: HugeIcons.strokeRoundedInvoice03,
                  eyebrow: 'Invoice snapshot',
                  title: 'Billing summary',
                ),
                const SizedBox(height: 12),
                _InvoiceRow(label: 'Order ID', value: order.orderId ?? '-'),
                _InvoiceRow(label: 'Customer', value: customerName),
                _InvoiceRow(label: 'Phone', value: customerPhone),
                _InvoiceRow(label: 'Address', value: customerAddress),
                _InvoiceRow(label: 'Payment', value: gatewayText),
                _InvoiceRow(label: 'Delivery', value: deliveryText),
                const Divider(height: 24, color: AppColor.safe),
                _InvoiceRow(
                  label: 'Subtotal',
                  value: '৳${convertToBengaliNumber(subtotal)}',
                ),
                if (discount > 0)
                  _InvoiceRow(
                    label: 'Discount',
                    value: '-৳${convertToBengaliNumber(discount)}',
                    valueColor: AppColor.green,
                  ),
                _InvoiceRow(
                  label: 'Delivery charge',
                  value: '৳${convertToBengaliNumber(deliveryCharge)}',
                ),
                _InvoiceRow(
                  label: 'Total',
                  value: '৳${convertToBengaliNumber(total)}',
                  emphasize: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLead(
                  icon: HugeIcons.strokeRoundedShoppingBasket01,
                  eyebrow: 'Purchased items',
                  title: 'Invoice lines',
                ),
                const SizedBox(height: 12),
                ...order.lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InvoiceLineTile(line: line),
                  ),
                ),
                if (order.lines.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColor.safe),
                    ),
                    child: Text(
                      'Item details are not available for this invoice yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                final previewLines = order.lines
                    .take(3)
                    .map((line) => line.productName?.trim())
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(', ');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLead(
                      icon: HugeIcons.strokeRoundedShare08,
                      eyebrow: 'Spread the word',
                      title: 'Share this order',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      previewLines.isEmpty
                          ? 'Share the store link so someone else can browse the same storefront.'
                          : 'Share the store and purchased items so someone else can reopen the same shopping context.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (previewLines.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.safe1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColor.safe),
                        ),
                        child: Text(
                          previewLines,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColor.text,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canShare
                            ? () {
                                final text =
                                    SellHubShareLinkBuilder.buildOrderShareText(
                                      store: activeStore,
                                      order: order,
                                    );
                                Share.share(text, subject: 'SellHub order');
                              }
                            : null,
                        icon: const AppHugeIcon(
                          HugeIcons.strokeRoundedShare08,
                          size: 18,
                        ),
                        label: const Text('Share order and store'),
                      ),
                    ),
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
                  onPressed: () => AppRouter.goToOrders(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColor.safe),
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text('Open orders'),
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
                    'Continue shopping',
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

class _OrderStage {
  const _OrderStage(this.label, this.icon);

  final String label;
  final List<List<dynamic>> icon;
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
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

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
                color:
                    valueColor ??
                    (emphasize ? AppColor.primary : AppColor.text),
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLineTile extends StatelessWidget {
  const _InvoiceLineTile({required this.line});

  final Line line;

  @override
  Widget build(BuildContext context) {
    final quantity = line.quantity ?? 0;
    final price = line.price ?? 0;
    final total = quantity * price;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedPackage,
              size: 18,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (line.productName ?? '').trim().isEmpty
                      ? 'Product'
                      : line.productName!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((line.variant ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    line.variant!.trim(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x$quantity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '৳${convertToBengaliNumber(total)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
