import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/store/store_scope.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';
import 'package:sellhub/features/orders/screens/order_details_screen.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';
import 'package:sellhub/injection_container.dart' as di;

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const Map<int, String> _statusNames = <int, String>{
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
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatefulWidget {
  const _OrdersView();

  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  int _customerId = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final customerId = await LocalStorage.getCustomerID() ?? 0;
    _customerId = customerId;
    if (!mounted) return;
    await context.read<OrdersCubit>().fetchOrders(
      siteId: StoreScope.activeSiteId(context),
      customerId: customerId,
    );
  }

  bool _canRequestCancel(int? status) {
    final current = status ?? 0;
    return current >= 0 && current <= 3;
  }

  Future<void> _openSupportSheet(OrderHistoryResModelProfile order) async {
    final store = context.read<StorefrontCubit>().state.siteDetails;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OrderSupportSheet(
        order: order,
        storeTitle: store?.title,
        storePhone: store?.phone?.toString(),
        storeEmail: store?.email,
      ),
    );
  }

  Future<void> _sendSupportRequest(OrderHistoryResModelProfile order) async {
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
      final message =
          cubit.state.actionError?.title ?? 'Unable to send support request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Support request sent to the store.');
    await _openSupportSheet(order);
  }

  Future<void> _requestCancel(OrderHistoryResModelProfile order) async {
    final cubit = context.read<OrdersCubit>();
    final siteId = StoreScope.activeSiteId(context);
    final userId = await LocalStorage.getUserID() ?? 0;
    final ok = await cubit.createCustomerCancelRequest(
      userId: userId,
      siteId: siteId,
      orderId: order.id ?? 0,
      orderLabel: order.orderId ?? 'Order',
    );
    if (!mounted) return;
    if (!ok) {
      final message = cubit.state.actionError?.title ??
          'Unable to send cancellation request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Cancellation request sent to the store.');
  }

  Future<void> _reorder(OrderHistoryResModelProfile order) async {
    final orderId = order.orderId ?? 'Order';
    await Clipboard.setData(
      ClipboardData(
        text: 'Reorder reference: $orderId',
      ),
    );
    if (!mounted) return;
    CustomToast.info('Order reference copied. Shop again to reorder.');
    AppRouter.goToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SellHubTopAppBar(
        title: 'Orders',
        icon: HugeIcons.strokeRoundedInvoice03,
        showBackButton: true,
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final filtered = state.filteredOrders;
          return RefreshIndicator(
            onRefresh: _loadOrders,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OrdersHero(
                  total: '${state.orders.length}',
                  delivered:
                      '${state.orders.where((order) => order.status == 10).length}',
                  open:
                      '${state.orders.where((order) => (order.status ?? 0) < 9).length}',
                ),
                const SizedBox(height: 16),
                const _OrdersFilterLead(),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: state.filterStatus == null,
                      onSelected: (_) =>
                          context.read<OrdersCubit>().setFilter(null),
                    ),
                    ...OrdersScreen._statusNames.entries.map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected: state.filterStatus == entry.key,
                        onSelected: (_) =>
                            context.read<OrdersCubit>().setFilter(entry.key),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.loading && state.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_customerId == 0)
                  const _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedLogin02,
                    title: 'Sign in to view your orders',
                    subtitle:
                        'SellHub can only load order history for an authenticated store customer.',
                  )
                else if (state.error != null)
                  _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedReceiptDollar,
                    title: state.error!.title,
                    subtitle: 'Pull to refresh and try again.',
                  )
                else if (filtered.isEmpty)
                  const _OrdersEmptyState(
                    icon: HugeIcons.strokeRoundedPackage01,
                    title: 'No orders yet',
                    subtitle: 'Your confirmed purchases will appear here.',
                  )
                else
                  ...filtered.map(
                    (order) => InkWell(
                      onTap: () {
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
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColor.safe),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order',
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          color: AppColor.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    order.orderId ?? 'Order',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _StatusPill(
                                        label: OrdersScreen._statusNames[order.status] ?? 'Pending',
                                      ),
                                      _MetaPill(label: formatDateTime(order.updatedAt)),
                                    ],
                                  ),
                                  if ((order.customerAddress?.trim().isNotEmpty ?? false))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        order.customerAddress!.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColor.neutral2,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _ActionChipButton(
                                        label: 'Support',
                                        icon: HugeIcons.strokeRoundedHelpCircle,
                                        onTap: () => _sendSupportRequest(order),
                                        isBusy:
                                            state.actionSubmitting &&
                                            state.actionOrderId == order.id,
                                      ),
                                      _ActionChipButton(
                                        label: 'Reorder',
                                        icon: HugeIcons.strokeRoundedReload,
                                        onTap: () => _reorder(order),
                                        isBusy: false,
                                      ),
                                      if (_canRequestCancel(order.status))
                                        _ActionChipButton(
                                          label: 'Cancel',
                                          icon: HugeIcons.strokeRoundedCancel01,
                                          onTap: () => _requestCancel(order),
                                          isBusy:
                                              state.actionSubmitting &&
                                              state.actionOrderId == order.id,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '৳ ${order.total?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.safe1,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Open',
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          color: AppColor.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const AppHugeIcon(
                                  HugeIcons.strokeRoundedArrowRight02,
                                  size: 16,
                                  color: AppColor.neutral2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

class _OrderSupportSheet extends StatelessWidget {
  const _OrderSupportSheet({
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
    final contactRows = <({String label, String value})>[
      if ((storeTitle ?? '').trim().isNotEmpty)
        (label: 'Store', value: storeTitle!.trim()),
      if ((storePhone ?? '').trim().isNotEmpty)
        (label: 'Phone', value: storePhone!.trim()),
      if ((storeEmail ?? '').trim().isNotEmpty)
        (label: 'Email', value: storeEmail!.trim()),
      (label: 'Order ID', value: orderId),
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
            'Share your order reference with the store for cancel, return, or reorder help.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...contactRows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SupportRow(label: row.label, value: row.value),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final text = StringBuffer('Support reference\n');
                for (final row in contactRows) {
                  text.writeln('${row.label}: ${row.value}');
                }
                await Clipboard.setData(ClipboardData(text: text.toString()));
                if (!context.mounted) return;
                CustomToast.success('Support details copied');
                Navigator.of(context).pop();
              },
              child: const Text('Copy support details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.label, required this.value});

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

class _OrdersHero extends StatelessWidget {
  const _OrdersHero({
    required this.total,
    required this.delivered,
    required this.open,
  });

  final String total;
  final String delivered;
  final String open;

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const AppHugeIcon(
                  HugeIcons.strokeRoundedInvoice03,
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
                      'Order history',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColor.text,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track active, delivered, and previous purchases.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w600,
                          ),
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
            children: [
              _OrdersSummaryChip(label: 'Total', value: total),
              _OrdersSummaryChip(label: 'Delivered', value: delivered),
              _OrdersSummaryChip(label: 'Open', value: open),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrdersFilterLead extends StatelessWidget {
  const _OrdersFilterLead();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const AppHugeIcon(
            HugeIcons.strokeRoundedFilterHorizontal,
            size: 16,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Filter by order stage',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _OrdersSummaryChip extends StatelessWidget {
  const _OrdersSummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState({
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
      padding: const EdgeInsets.only(top: 44),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AppHugeIcon(icon, size: 28, color: AppColor.primary),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.neutral2,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(999),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColor.neutral2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
