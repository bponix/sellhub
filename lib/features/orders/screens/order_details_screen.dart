import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/custom_toast.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/orders/data/models/order_event_model.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
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

  @override
  void initState() {
    super.initState();
    _eventsFuture = di.sl<OrdersRepository>().fetchOrderEvents(
      siteId: widget.siteId,
      orderId: widget.order.id ?? 0,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _eventsFuture = di.sl<OrdersRepository>().fetchOrderEvents(
        siteId: widget.siteId,
        orderId: widget.order.id ?? 0,
      );
    });
    await _eventsFuture;
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
      final message = cubit.state.actionError?.title ??
          'Unable to send support request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Support request sent to the store.');
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
      final message = cubit.state.actionError?.title ??
          'Unable to send cancellation request.';
      CustomToast.error(message);
      return;
    }
    CustomToast.success('Cancellation request sent to the store.');
    await _reload();
  }

  Future<void> _reorder() async {
    final orderId = widget.order.orderId ?? 'Order';
    await Clipboard.setData(
      ClipboardData(text: 'Reorder reference: $orderId'),
    );
    if (!mounted) return;
    CustomToast.info('Order reference copied. Shop again to reorder.');
    AppRouter.goToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SellHubTopAppBar(
        title: widget.order.orderId ?? 'Order details',
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
            BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, state) {
                final isBusy =
                    state.actionSubmitting &&
                    state.actionOrderId == widget.order.id;
                return _OrderActionPanel(
                  onSupport: _openSupportSheet,
                  onReorder: _reorder,
                  onCancel: _canRequestCancel() ? _requestCancel : null,
                  isBusy: isBusy,
                );
              },
            ),
            const SizedBox(height: 16),
            _OrderProgressPanel(order: widget.order),
            const SizedBox(height: 16),
            _QuickStatusStrip(order: widget.order),
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
    required this.onSupport,
    required this.onReorder,
    required this.onCancel,
    this.isBusy = false,
  });

  final VoidCallback onSupport;
  final VoidCallback onReorder;
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
      child: Wrap(
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
            label: 'Reorder',
            icon: HugeIcons.strokeRoundedReload,
            onTap: onReorder,
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
    final rows = <({String label, String value})>[
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
            'Use these support details for cancel, return, delivery, or reorder questions.',
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
                final buffer = StringBuffer('Support reference\n');
                for (final row in rows) {
                  buffer.writeln('${row.label}: ${row.value}');
                }
                await Clipboard.setData(ClipboardData(text: buffer.toString()));
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OrderSectionLead(
            icon: HugeIcons.strokeRoundedPackageSearch01,
            eyebrow: 'Order snapshot',
            title: 'Order details',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                label: _statusNames[order.status] ?? 'Pending',
                toneColor: AppColor.primary,
                background: AppColor.primarySoft,
              ),
              _HeroPill(
                label: formatDateTime(order.updatedAt),
                toneColor: AppColor.neutral2,
                background: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            order.orderId ?? 'Order',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '৳ ${order.total?.toStringAsFixed(0) ?? '0'}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(height: 16),
          _OrderMetaRow(label: 'Customer', value: order.customerName ?? 'Customer'),
          _OrderMetaRow(
            label: 'Phone',
            value: '${order.customerPhone ?? ''}',
          ),
          _OrderMetaRow(
            label: 'Address',
            value: order.customerAddress ?? 'No address provided',
          ),
          if ((order.customerNote ?? '').trim().isNotEmpty)
            _OrderMetaRow(label: 'Note', value: order.customerNote!.trim()),
        ],
      ),
    );
  }
}

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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.safe),
            ),
            child: Row(
              children: [
                const AppHugeIcon(
                  HugeIcons.strokeRoundedCustomerSupport,
                  size: 18,
                  color: AppColor.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Latest delivery and support context is shown here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColor.neutral2,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
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

class _QuickStatusStrip extends StatelessWidget {
  const _QuickStatusStrip({required this.order});

  final OrderHistoryResModelProfile order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusStripTile(
            icon: HugeIcons.strokeRoundedCalendar03,
            label: 'Updated',
            value: formatDateTime(order.updatedAt),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatusStripTile(
            icon: HugeIcons.strokeRoundedCall02,
            label: 'Phone',
            value: '${order.customerPhone ?? ''}'.isEmpty
                ? 'Unavailable'
                : '${order.customerPhone ?? ''}',
          ),
        ),
      ],
    );
  }
}

class _StatusStripTile extends StatelessWidget {
  const _StatusStripTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppHugeIcon(icon, size: 16, color: AppColor.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
              ),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
            ),
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
                Container(
                  width: 2,
                  height: 72,
                  color: AppColor.safe,
                ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColor.neutral2,
                    ),
                  ),
                  if (event.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.address.trim(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.neutral2,
                      ),
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
