import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/formatDateTime.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/cart/screens/quote_preview_screen.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sellhub/injection_container.dart' as di;

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  Future<List<ResellerQuote>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadQuotes();
  }

  Future<List<ResellerQuote>> _loadQuotes() async {
    final siteId =
        context.read<StoreContextCubit>().state.activeStore?.siteId ?? 0;
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0 || siteId <= 0) return const <ResellerQuote>[];
    return di.sl<ProfileRepository>().fetchQuotes(
      userId: userId,
      siteId: siteId,
    );
  }

  Future<void> _refresh() async {
    final future = _loadQuotes();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _deleteQuote(String quoteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete quote'),
          content: const Text('Delete this saved quote from your quote desk?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await di.sl<ProfileRepository>().deleteQuote(quoteId);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Quotes',
        subtitle: 'Saved buyer quotes and converted sell paths',
        icon: HugeIcons.strokeRoundedInvoice03,
        showBackButton: true,
      ),
      body: FutureBuilder<List<ResellerQuote>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _QuotesEmptyState(
              icon: HugeIcons.strokeRoundedAlert02,
              title: 'Unable to load quotes',
              subtitle: 'Pull to refresh and try again.',
              onRetry: _refresh,
            );
          }
          final quotes = snapshot.data ?? const <ResellerQuote>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _QuotesHero(),
                const SizedBox(height: 16),
                if (quotes.isEmpty)
                  _QuotesEmptyState(
                    icon: HugeIcons.strokeRoundedInvoice03,
                    title: 'Quote desk starts here',
                    subtitle:
                        'Shared and saved buyer quotes will stay here until they convert or you clear them.',
                    onRetry: _refresh,
                  )
                else
                  ...quotes.map(
                    (quote) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuoteCard(
                        quote: quote,
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => QuotePreviewScreen(quote: quote),
                            ),
                          );
                        },
                        onShare: () async {
                          final activeStore = context
                              .read<StoreContextCubit>()
                              .state
                              .activeStore;
                          if (activeStore == null) return;
                          await Share.share(
                            SellHubShareLinkBuilder.buildQuoteShareText(
                              store: activeStore,
                              quote: quote,
                            ),
                            subject: 'Quote ${quote.id}',
                          );
                        },
                        onDelete: quote.status == 'offline'
                            ? () async {
                                await _deleteQuote(quote.id);
                              }
                            : null,
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

class _QuotesHero extends StatelessWidget {
  const _QuotesHero();

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
              HugeIcons.strokeRoundedInvoice03,
              size: 20,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quote desk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reopen a buyer quote, share it again, or verify that it converted into an order.',
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
    );
  }
}

class _QuotesEmptyState extends StatelessWidget {
  const _QuotesEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRetry;

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
                onPressed: () => onRetry(),
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.onOpen,
    required this.onShare,
    this.onDelete,
  });

  final ResellerQuote quote;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isConverted = quote.status.toLowerCase() == 'converted';
    final isOffline = quote.status.toLowerCase() == 'offline';
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
                  quote.buyerName.trim().isEmpty
                      ? 'Buyer quote'
                      : quote.buyerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(
                label: isConverted
                    ? 'Converted'
                    : (isOffline ? 'Offline draft' : 'Store draft'),
                color: isConverted
                    ? AppColor.primary
                    : (isOffline ? AppColor.alert : AppColor.neutral2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: 'Total ৳${quote.total}'),
              _MetaPill(label: '${quote.lines.length} items'),
              _MetaPill(label: quote.deliveryEstimate),
              if ((quote.orderId ?? '').trim().isNotEmpty)
                _MetaPill(label: 'Order ${quote.orderId}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${quote.buyerPhone} • ${quote.deliveryLabel}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved ${formatDateTime(quote.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onOpen,
                  child: const Text('Open quote'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onShare,
                  child: const Text('Share'),
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete offline draft',
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedDelete02,
                    size: 18,
                    color: AppColor.alert,
                  ),
                ),
            ],
          ),
        ],
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
          color: AppColor.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
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
