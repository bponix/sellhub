import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';

class MultiOrderCompleteScreen extends StatelessWidget {
  const MultiOrderCompleteScreen({
    super.key,
    required this.orders,
  });

  final List<OrderCreateRes> orders;

  @override
  Widget build(BuildContext context) {
    final total = orders.fold<int>(
      0,
      (sum, order) => sum + (order.total ?? 0),
    );
    final itemCount = orders.fold<int>(
      0,
      (sum, order) =>
          sum +
          order.lines.fold<int>(
            0,
            (lineSum, line) => lineSum + (line.quantity ?? 0),
          ),
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Orders created',
        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split supplier orders created',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This selling list was split across ${orders.length} suppliers. Track each order separately in the queue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Orders',
                        value: '${orders.length}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Items',
                        value: '$itemCount',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Buyer total',
                        value: '৳${convertToBengaliNumber(total)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _LegPill(label: 'Next: Open orders'),
              _LegPill(label: 'Route: Split'),
              _LegPill(label: '${orders.length} supplier legs'),
            ],
          ),
          const SizedBox(height: 16),
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SupplierLegCard(order: order),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => AppRouter.goToOrders(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColor.safe),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Open orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => AppRouter.goToHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

class _SupplierLegCard extends StatelessWidget {
  const _SupplierLegCard({required this.order});

  final OrderCreateRes order;

  @override
  Widget build(BuildContext context) {
    final supplierScope = order.lines
        .map((line) => (line.source ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(', ');
    final supplierLabel = supplierScope.isEmpty ? 'Supplier leg' : supplierScope;
    final itemCount = order.lines.fold<int>(
      0,
      (sum, line) => sum + (line.quantity ?? 0),
    );
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedPackageMoving,
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
                      order.orderId ?? 'Order',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supplierLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w700,
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
              _LegPill(label: '$itemCount items'),
              _LegPill(
                label:
                    (order.logisticsText ?? '').trim().isEmpty
                        ? 'Delivery lane pending'
                        : order.logisticsText!.trim(),
              ),
              _LegPill(
                label:
                    (order.gatewayText ?? '').trim().isEmpty
                        ? 'Payment pending'
                        : order.gatewayText!.trim(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Buyer total',
                  value: '৳${convertToBengaliNumber(order.total ?? 0)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Base',
                  value: '৳${convertToBengaliNumber(order.resellAmount ?? 0)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryTile(
                  label: 'Profit',
                  value: '৳${convertToBengaliNumber(order.profit ?? 0)}',
                ),
              ),
            ],
          ),
          if (order.lines.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...order.lines.take(3).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.productName ?? 'Product',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'x${line.quantity ?? 0} • ৳${convertToBengaliNumber(line.price ?? 0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegPill extends StatelessWidget {
  const _LegPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
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
