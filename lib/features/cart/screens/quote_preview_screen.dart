import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/sellhub_top_app_bar.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';

class QuotePreviewScreen extends StatefulWidget {
  const QuotePreviewScreen({super.key, required this.quote});

  final ResellerQuote quote;

  @override
  State<QuotePreviewScreen> createState() => _QuotePreviewScreenState();
}

class _QuotePreviewScreenState extends State<QuotePreviewScreen> {
  int _selectedVariantIndex = 0;

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final shareVariants = _buildQuoteShareVariants(
      storeName: activeStore?.title?.trim(),
      quote: quote,
    );
    final activeVariant = shareVariants[_selectedVariantIndex];
    final buyerShareText = activeVariant.body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const SellHubTopAppBar(
        title: 'Quote preview',
        icon: HugeIcons.strokeRoundedInvoice03,
        showBackButton: true,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppColor.safe)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Share.share(
                      buyerShareText,
                      subject: activeVariant.title,
                    );
                  },
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedShare08,
                    size: 16,
                  ),
                  label: const Text('Share quote'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text('Buyer confirmed'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColor.safe),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _MetaPill(label: 'Buyer-ready'),
                    _MetaPill(label: quote.deliveryLabel),
                    _MetaPill(
                      label: 'Total ৳${convertToBengaliNumber(quote.total)}',
                    ),
                    _MetaPill(label: activeVariant.label),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  activeStore?.title?.trim().isNotEmpty == true
                      ? activeStore!.title!.trim()
                      : 'Quote preview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buyer-ready quote',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _QuoteTrustStrip(quote: quote),
                const SizedBox(height: 16),
                Container(
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
                        quote.buyerName.trim().isEmpty
                            ? 'Buyer quote'
                            : 'Prepared for ${quote.buyerName}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColor.text,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _QuoteMetricRow(
                        label: 'Delivery',
                        value:
                            '${quote.deliveryLabel} • ${quote.deliveryEstimate}',
                      ),
                      _QuoteMetricRow(
                        label: 'Address',
                        value: quote.buyerAddress.trim().isEmpty
                            ? 'Shared in chat after confirmation'
                            : quote.buyerAddress,
                      ),
                      _QuoteMetricRow(
                        label: 'Payment',
                        value: 'Cash on delivery',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColor.safe),
                const SizedBox(height: 12),
                ...quote.lines.map((line) => _QuoteLineCard(line: line)),
                const SizedBox(height: 10),
                const Divider(color: AppColor.safe),
                const SizedBox(height: 10),
                _QuoteMetricRow(
                  label: 'Subtotal',
                  value: '৳${convertToBengaliNumber(quote.subtotal)}',
                ),
                _QuoteMetricRow(
                  label: 'Delivery charge',
                  value: '৳${convertToBengaliNumber(quote.deliveryCharge)}',
                ),
                _QuoteMetricRow(
                  label: 'Buyer total',
                  value: '৳${convertToBengaliNumber(quote.total)}',
                  isStrong: true,
                ),
              ],
            ),
          ),
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
                Text(
                  'Message preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _MetaPill(label: 'WhatsApp-ready'),
                    const _MetaPill(label: 'Facebook-ready'),
                    const _MetaPill(label: 'Bangla + English'),
                    _MetaPill(label: '${quote.lines.length} items'),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shareVariants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final variant = shareVariants[index];
                      final selected = index == _selectedVariantIndex;
                      return ChoiceChip(
                        label: Text(variant.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedVariantIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
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
                        activeVariant.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColor.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeVariant.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(16),
                  ),
                    child: Text(
                      buyerShareText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionChip(
                      icon: HugeIcons.strokeRoundedWhatsapp,
                      label: 'WhatsApp',
                      onTap: () async {
                        await Share.share(
                          buyerShareText,
                          subject: activeVariant.title,
                        );
                      },
                    ),
                    _ActionChip(
                      icon: HugeIcons.strokeRoundedFacebook02,
                      label: 'Facebook',
                      onTap: () async {
                        await Share.share(
                          buyerShareText,
                          subject: activeVariant.title,
                        );
                      },
                    ),
                    _ActionChip(
                      icon: HugeIcons.strokeRoundedCopy01,
                      label: 'Copy text',
                      onTap: () async {
                        await Clipboard.setData(
                          ClipboardData(text: buyerShareText),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Buyer-ready quote text copied'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
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
                Text(
                  'Internal operator details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(label: 'Quote ${quote.id}'),
                    _MetaPill(label: 'Status ${quote.status}'),
                    _MetaPill(
                      label: 'Profit ৳${convertToBengaliNumber(quote.profit)}',
                    ),
                    _MetaPill(
                      label: 'Base ৳${convertToBengaliNumber(quote.baseTotal)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _QuoteMetricRow(
                  label: 'Buyer phone',
                  value: '${quote.buyerPhone}',
                ),
                _QuoteMetricRow(
                  label: 'Created',
                  value: _formatCreatedAt(quote.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteShareVariant {
  const _QuoteShareVariant({
    required this.title,
    required this.label,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String label;
  final String subtitle;
  final String body;
}

class _QuoteTrustStrip extends StatelessWidget {
  const _QuoteTrustStrip({required this.quote});

  final ResellerQuote quote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        const _MetaPill(label: 'Cash on delivery'),
        _MetaPill(label: quote.deliveryEstimate),
        _MetaPill(
          label: 'Clear total ৳${convertToBengaliNumber(quote.total)}',
        ),
      ],
    );
  }
}

class _QuoteLineCard extends StatelessWidget {
  const _QuoteLineCard({required this.line});

  final ResellerQuoteLine line;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: line.thumbnail.trim().isEmpty
                ? Container(
                    width: 54,
                    height: 54,
                    color: AppColor.safe1,
                    alignment: Alignment.center,
                    child: const AppHugeIcon(
                      HugeIcons.strokeRoundedPackage,
                      size: 18,
                      color: AppColor.primary,
                    ),
                  )
                : AppNetworkImage(
                    imageUrl: line.thumbnail,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty ${line.quantity} • Unit ৳${convertToBengaliNumber(line.sellPrice)}',
                  style: const TextStyle(
                    color: AppColor.neutral2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '৳${convertToBengaliNumber(line.lineSellTotal)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColor.safe),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppHugeIcon(icon, size: 14, color: AppColor.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColor.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteMetricRow extends StatelessWidget {
  const _QuoteMetricRow({
    required this.label,
    required this.value,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isStrong ? AppColor.primary : AppColor.text,
                fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
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
        border: Border.all(color: AppColor.safe),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColor.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _buildBuyerShareText({
  required String? storeName,
  required ResellerQuote quote,
}) {
  final seller = (storeName ?? '').trim().isEmpty
      ? 'Our store'
      : storeName!.trim();
  final lines = quote.lines
      .map(
        (line) =>
            '- ${line.title} x${line.quantity} — ৳${convertToBengaliNumber(line.lineSellTotal)}',
      )
      .join('\n');
  final trustLine =
      'Buyer total: ৳${convertToBengaliNumber(quote.total)} • Delivery: ${quote.deliveryEstimate} • Payment: Cash on delivery';
  return '$seller\n'
      'Quote for ${quote.buyerName}\n'
      '$trustLine\n'
      '$lines\n'
      'Subtotal: ৳${convertToBengaliNumber(quote.subtotal)}\n'
      'Delivery: ৳${convertToBengaliNumber(quote.deliveryCharge)} (${quote.deliveryEstimate})\n'
      'Total: ৳${convertToBengaliNumber(quote.total)}\n'
      'Payment: Cash on delivery\n'
      'Reply here to confirm your order.';
}

List<_QuoteShareVariant> _buildQuoteShareVariants({
  required String? storeName,
  required ResellerQuote quote,
}) {
  final seller = (storeName ?? '').trim().isEmpty
      ? 'SellHub reseller'
      : storeName!.trim();
  final productTitles = quote.lines
      .map((line) => line.title.trim())
      .where((title) => title.isNotEmpty)
      .take(2)
      .join(', ');
  final banglaLead = productTitles.isEmpty
      ? 'আপনার জন্য অফার প্রস্তুত আছে।'
      : '$productTitles নিয়ে আপনার জন্য অফার প্রস্তুত আছে।';
  final buyerName = quote.buyerName.trim().isEmpty ? 'buyer' : quote.buyerName.trim();
  final generic = _buildBuyerShareText(storeName: storeName, quote: quote);
  final trustLine =
      'Buyer total: ৳${convertToBengaliNumber(quote.total)} • ${quote.deliveryEstimate} • Cash on delivery';
  return <_QuoteShareVariant>[
    _QuoteShareVariant(
      title: 'WhatsApp buyer quote',
      label: 'WhatsApp',
      subtitle: 'Short and direct for inbox confirmation',
      body:
          'Assalamu Alaikum $buyerName,\n$banglaLead\n$trustLine\nঅর্ডার কনফার্ম করতে নাম, ঠিকানা, ফোন দিন।',
    ),
    _QuoteShareVariant(
      title: 'Facebook inbox caption',
      label: 'Facebook',
      subtitle: 'Slightly more promotional for page leads',
      body:
          '$seller\n$productTitles\n$trustLine\nInbox now to confirm your order.',
    ),
    _QuoteShareVariant(
      title: 'Bangla trust version',
      label: 'Bangla',
      subtitle: 'Trust-first copy for cautious buyers',
      body:
          '$buyerName,\n${productTitles.isEmpty ? 'অফার' : productTitles} এর কোট রেডি আছে।\n$trustLine\nকনফার্ম করলে আমরা অর্ডার সেটআপ করে দিব।',
    ),
    _QuoteShareVariant(
      title: 'English follow-up',
      label: 'English',
      subtitle: 'Simple English version for mixed-language chats',
      body:
          'Hi $buyerName,\nYour quote is ready for ${productTitles.isEmpty ? 'the selected items' : productTitles}.\n$trustLine\nReply with your name, phone, and address to confirm.',
    ),
    _QuoteShareVariant(
      title: 'Full quote summary',
      label: 'Full',
      subtitle: 'Detailed buyer-facing quote with line items',
      body: generic,
    ),
  ];
}

String _formatCreatedAt(DateTime dateTime) {
  final month = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][dateTime.month - 1];
  final hour = dateTime.hour > 12
      ? dateTime.hour - 12
      : (dateTime.hour == 0 ? 12 : dateTime.hour);
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${dateTime.day} $month ${dateTime.year}, $hour:$minute $suffix';
}
