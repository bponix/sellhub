import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/profile/data/model/workflow_automation_overview.dart';
import 'package:sellhub/features/profile/data/model/workflow_buyer_segment.dart';
import 'package:sellhub/features/profile/data/model/workflow_pricing_template.dart';
import 'package:sellhub/features/profile/data/model/workflow_recent_pairing.dart';
import 'package:sellhub/features/profile/data/model/workflow_sell_again_suggestion.dart';
import 'package:sellhub/features/profile/data/model/workflow_supplier_bundle.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/injection_container.dart' as di;

class WorkflowAutomationScreen extends StatefulWidget {
  const WorkflowAutomationScreen({super.key});

  @override
  State<WorkflowAutomationScreen> createState() =>
      _WorkflowAutomationScreenState();
}

class _WorkflowAutomationScreenState extends State<WorkflowAutomationScreen> {
  Future<WorkflowAutomationOverview>? _future;
  int? _userId;
  int? _siteId;

  @override
  void initState() {
    super.initState();
    _future = _loadOverview();
  }

  Future<WorkflowAutomationOverview> _loadOverview() async {
    final siteId =
        context.read<StoreContextCubit>().state.activeStore?.siteId ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    _userId = userId;
    _siteId = siteId;
    if (userId <= 0 || siteId <= 0) {
      return const WorkflowAutomationOverview(
        pricingTemplates: <WorkflowPricingTemplate>[],
        supplierBundles: <WorkflowSupplierBundle>[],
        buyerSegments: <WorkflowBuyerSegment>[],
        recentPairings: <WorkflowRecentPairing>[],
        sellAgainSuggestions: <WorkflowSellAgainSuggestion>[],
      );
    }
    return di.sl<ProfileRepository>().fetchWorkflowAutomationOverview(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<void> _refresh() async {
    final future = _loadOverview();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _editTemplate([WorkflowPricingTemplate? existing]) async {
    if (_userId == null || _siteId == null) return;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final channelController = TextEditingController(
      text: existing?.channel ?? 'WhatsApp',
    );
    final amountController = TextEditingController(
      text: (existing?.markupAmount ?? 0).toStringAsFixed(0),
    );
    final percentController = TextEditingController(
      text: (existing?.markupPercent ?? 0).toStringAsFixed(0),
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            existing == null ? 'New pricing template' : 'Edit template',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Template name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: channelController,
                  decoration: const InputDecoration(labelText: 'Channel'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Markup amount'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: percentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Markup %'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop('delete'),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (action == null) return;
    final repo = di.sl<ProfileRepository>();
    if (action == 'delete' && existing != null) {
      await repo.deleteWorkflowPricingTemplate(existing.id);
      await _refresh();
      return;
    }
    if (action != 'save') return;
    await repo.upsertWorkflowPricingTemplate(
      WorkflowPricingTemplate(
        id:
            existing?.id ??
            'pricing-${_siteId!}-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId!,
        siteId: _siteId!,
        name: nameController.text.trim().isEmpty
            ? 'Quick template'
            : nameController.text.trim(),
        channel: channelController.text.trim().isEmpty
            ? 'General'
            : channelController.text.trim(),
        markupAmount: double.tryParse(amountController.text.trim()) ?? 0,
        markupPercent: double.tryParse(percentController.text.trim()) ?? 0,
        note: noteController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    await _refresh();
  }

  Future<void> _editBundle([WorkflowSupplierBundle? existing]) async {
    if (_userId == null || _siteId == null) return;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final supplierController = TextEditingController(
      text: existing?.supplierName ?? '',
    );
    final productsController = TextEditingController(
      text: existing == null ? '' : existing.productTitles.join(', '),
    );
    final noteController = TextEditingController(text: existing?.note ?? '');
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(existing == null ? 'New supplier bundle' : 'Edit bundle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Bundle name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: productsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Products',
                    hintText: 'Comma separated titles',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop('delete'),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (action == null) return;
    final repo = di.sl<ProfileRepository>();
    if (action == 'delete' && existing != null) {
      await repo.deleteWorkflowSupplierBundle(existing.id);
      await _refresh();
      return;
    }
    if (action != 'save') return;
    await repo.upsertWorkflowSupplierBundle(
      WorkflowSupplierBundle(
        id:
            existing?.id ??
            'bundle-${_siteId!}-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId!,
        siteId: _siteId!,
        supplierName: supplierController.text.trim().isEmpty
            ? 'Supplier'
            : supplierController.text.trim(),
        name: nameController.text.trim().isEmpty
            ? 'Fast bundle'
            : nameController.text.trim(),
        productTitles: productsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
        note: noteController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    await _refresh();
  }

  Future<void> _editSegment([WorkflowBuyerSegment? existing]) async {
    if (_userId == null || _siteId == null) return;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final countController = TextEditingController(
      text: (existing?.buyerCount ?? 0).toString(),
    );
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(existing == null ? 'New buyer segment' : 'Edit segment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Segment name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Buyer count'),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null && !existing.id.startsWith('auto-'))
              TextButton(
                onPressed: () => Navigator.of(context).pop('delete'),
                child: const Text('Delete'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (action == null) return;
    final repo = di.sl<ProfileRepository>();
    if (action == 'delete' &&
        existing != null &&
        !existing.id.startsWith('auto-')) {
      await repo.deleteWorkflowBuyerSegment(existing.id);
      await _refresh();
      return;
    }
    if (action != 'save') return;
    await repo.upsertWorkflowBuyerSegment(
      WorkflowBuyerSegment(
        id:
            existing?.id ??
            'segment-${_siteId!}-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId!,
        siteId: _siteId!,
        name: nameController.text.trim().isEmpty
            ? 'Buyer segment'
            : nameController.text.trim(),
        description: descriptionController.text.trim(),
        buyerCount: int.tryParse(countController.text.trim()) ?? 0,
        updatedAt: DateTime.now(),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Workflows',
        subtitle: 'Device drafts for pricing, segments, and repeat selling',
        icon: HugeIcons.strokeRoundedReload,
        showBackButton: true,
      ),
      body: FutureBuilder<WorkflowAutomationOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _WorkflowEmptyState(
              icon: HugeIcons.strokeRoundedAlert02,
              title: 'Unable to load workflows',
              subtitle: 'Pull to refresh and try again.',
              onRefresh: _refresh,
            );
          }
          final overview = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _WorkflowHero(),
                const SizedBox(height: 12),
                const _InlineHintCard(
                  text:
                      'Device draft: these workflow shortcuts are not Store order, buyer, payout, or team truth.',
                ),
                const SizedBox(height: 16),
                _WorkflowSectionLead(
                  icon: HugeIcons.strokeRoundedInvoice03,
                  title: 'Pricing templates',
                  subtitle: 'Device-only margin preferences by channel.',
                  actionLabel: 'New template',
                  onAction: () => _editTemplate(),
                ),
                const SizedBox(height: 12),
                if (overview.pricingTemplates.isEmpty)
                  const _InlineHintCard(
                    text:
                        'Save your first pricing template to keep repeat quotes fast.',
                  )
                else
                  ...overview.pricingTemplates.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateCard(
                        item: item,
                        onTap: () => _editTemplate(item),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _WorkflowSectionLead(
                  icon: HugeIcons.strokeRoundedPackage,
                  title: 'Supplier bundles',
                  subtitle: 'Device-only product groups for quick reopening.',
                  actionLabel: 'New bundle',
                  onAction: () => _editBundle(),
                ),
                const SizedBox(height: 12),
                if (overview.supplierBundles.isEmpty)
                  const _InlineHintCard(
                    text:
                        'Save supplier bundles to reopen winning product groups faster.',
                  )
                else
                  ...overview.supplierBundles.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BundleCard(
                        item: item,
                        onTap: () => _editBundle(item),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                _WorkflowSectionLead(
                  icon: HugeIcons.strokeRoundedUserGroup,
                  title: 'Buyer segments',
                  subtitle:
                      'Device-only follow-up buckets for personal workflow.',
                  actionLabel: 'New segment',
                  onAction: () => _editSegment(),
                ),
                const SizedBox(height: 12),
                ...overview.buyerSegments.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SegmentCard(
                      item: item,
                      onTap: item.id.startsWith('auto-')
                          ? null
                          : () => _editSegment(item),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const _WorkflowSectionLead(
                  icon: HugeIcons.strokeRoundedLinkCircle02,
                  title: 'Recent buyer pairings',
                  subtitle: 'See which buyer-product pairs recently converted.',
                ),
                const SizedBox(height: 12),
                if (overview.recentPairings.isEmpty)
                  const _InlineHintCard(
                    text:
                        'Recent buyer pairings will appear after quotes convert into orders.',
                  )
                else
                  ...overview.recentPairings.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentPairingCard(item: item),
                    ),
                  ),
                const SizedBox(height: 18),
                const _WorkflowSectionLead(
                  icon: HugeIcons.strokeRoundedReload,
                  title: 'Sell again',
                  subtitle:
                      'Jump back into high-repeat products without rebuilding the flow.',
                ),
                const SizedBox(height: 12),
                if (overview.sellAgainSuggestions.isEmpty)
                  const _InlineHintCard(
                    text:
                        'Delivered orders will seed sell-again suggestions here.',
                  )
                else
                  ...overview.sellAgainSuggestions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SellAgainCard(item: item),
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

class _WorkflowHero extends StatelessWidget {
  const _WorkflowHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppHugeIcon(
              HugeIcons.strokeRoundedReload,
              size: 20,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keep reusable reseller decisions here so repeat selling starts from saved defaults instead of retyping the same rules.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowSectionLead extends StatelessWidget {
  const _WorkflowSectionLead({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
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
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
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
        ),
        if (actionLabel != null && onAction != null)
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _InlineHintCard extends StatelessWidget {
  const _InlineHintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColor.neutral2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.item, required this.onTap});

  final WorkflowPricingTemplate item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WorkflowCardShell(
      title: item.name,
      subtitle: '${item.channel} • Updated ${formatDateTime(item.updatedAt)}',
      body:
          'Markup ৳${item.markupAmount.toStringAsFixed(0)} • ${item.markupPercent.toStringAsFixed(0)}%',
      note: item.note,
      onTap: onTap,
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.item, required this.onTap});

  final WorkflowSupplierBundle item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _WorkflowCardShell(
      title: item.name,
      subtitle:
          '${item.supplierName} • ${item.productTitles.length} products • ${formatDateTime(item.updatedAt)}',
      body: item.productTitles.join(', '),
      note: item.note,
      onTap: onTap,
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({required this.item, this.onTap});

  final WorkflowBuyerSegment item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _WorkflowCardShell(
      title: item.name,
      subtitle: '${item.buyerCount} buyers • ${formatDateTime(item.updatedAt)}',
      body: item.description,
      note: item.id.startsWith('auto-') ? 'Auto-derived' : 'Saved segment',
      onTap: onTap,
    );
  }
}

class _RecentPairingCard extends StatelessWidget {
  const _RecentPairingCard({required this.item});

  final WorkflowRecentPairing item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.buyerName} • ৳${item.sellPrice.toStringAsFixed(0)} • ${formatDateTime(item.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Order ${item.orderId} • ${item.buyerPhone}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SellAgainCard extends StatelessWidget {
  const _SellAgainCard({required this.item});

  final WorkflowSellAgainSuggestion item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColor.safe1,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.repeatCount}x sold',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.lastBuyerName} • ৳${item.lastSellPrice.toStringAsFixed(0)} • ${formatDateTime(item.lastOrderedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => AppRouter.pushSearchScreen(
              context,
              mode: 'repeat-sell',
              query: item.productTitle,
            ),
            child: const Text('Find product'),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCardShell extends StatelessWidget {
  const _WorkflowCardShell({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.note,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String body;
  final String note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                note,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColor.neutral2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkflowEmptyState extends StatelessWidget {
  const _WorkflowEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColor.safe),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppHugeIcon(icon, size: 40, color: AppColor.neutral2),
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => onRefresh(),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
