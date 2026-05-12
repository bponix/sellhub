import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:hugeicons/hugeicons.dart';

class ProductShareSheet {
  const ProductShareSheet._();

  static Future<void> show({
    required BuildContext context,
    required ActiveStore store,
    required ProductResCommon product,
    String? referCode,
  }) async {
    final link = SellHubShareLinkBuilder.buildProductUri(
      store: store,
      product: product,
      referCode: referCode,
    ).toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ProductShareSheetBody(store: store, product: product, link: link),
    );
  }
}

class _ProductShareSheetBody extends StatefulWidget {
  const _ProductShareSheetBody({
    required this.store,
    required this.product,
    required this.link,
  });

  final ActiveStore store;
  final ProductResCommon product;
  final String link;

  @override
  State<_ProductShareSheetBody> createState() => _ProductShareSheetBodyState();
}

class _ProductShareSheetBodyState extends State<_ProductShareSheetBody> {
  final GlobalKey _squareCardKey = GlobalKey();
  final GlobalKey _storyCardKey = GlobalKey();
  final GlobalKey _ctaCardKey = GlobalKey();
  bool _sharingImage = false;

  @override
  Widget build(BuildContext context) {
    final model = _SocialShareModel.fromProduct(
      store: widget.store,
      product: widget.product,
      link: widget.link,
    );
    final copyVariants = _buildCopyVariants(model);
    final imageVariants = _buildImageVariants();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColor.safe),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.safe,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            _HeaderCard(model: model),
            const SizedBox(height: 14),
            _PricingGuide(model: model),
            const SizedBox(height: 14),
            _SectionTitle(
              icon: HugeIcons.strokeRoundedMessage02,
              title: 'Social copy',
              subtitle:
                  'Generate one-tap copy for messaging, feed posts, and fast reseller negotiation.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ListView.separated(
                itemCount: copyVariants.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final variant = copyVariants[index];
                  return _CopyVariantCard(
                    variant: variant,
                    onCopy: () => _copyText(variant.body, variant.copyToast),
                    onShare: () => Share.share(
                      variant.body,
                      subject: '${model.title} • ${variant.title}',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _SectionTitle(
              icon: HugeIcons.strokeRoundedImage02,
              title: 'Share cards',
              subtitle:
                  'Use visual cards for WhatsApp status, Facebook posts, and quick CTA selling.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 360,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageVariants.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final variant = imageVariants[index];
                  return _ImageVariantTile(
                    title: variant.title,
                    subtitle: variant.subtitle,
                    boundaryKey: variant.key,
                    onShare: _sharingImage
                        ? null
                        : () => _shareImageCard(
                            key: variant.key,
                            filename: variant.filename,
                            shareText: model.orderNowTemplate,
                          ),
                    child: _ShareVisualCard(
                      model: model,
                      layout: variant.layout,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedCopy01,
                    label: 'Copy order message',
                    onTap: () => _copyText(
                      model.orderNowTemplate,
                      'Order message copied.',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedEdit02,
                    label: 'Edited offer',
                    onTap: () => _duplicateOfferWithEditedPrice(model),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedShare08,
                    label: 'Share best copy',
                    primary: true,
                    onTap: () => Share.share(
                      copyVariants.first.body,
                      subject: model.title,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_ImageVariant> _buildImageVariants() {
    return <_ImageVariant>[
      _ImageVariant(
        title: 'Square share card',
        subtitle: 'Best for Facebook post or feed share',
        key: _squareCardKey,
        filename: 'sellhub_square_share.png',
        layout: _ShareVisualLayout.square,
      ),
      _ImageVariant(
        title: 'Story-friendly card',
        subtitle: 'Best for status, story, or full-screen pitch',
        key: _storyCardKey,
        filename: 'sellhub_story_share.png',
        layout: _ShareVisualLayout.story,
      ),
      _ImageVariant(
        title: 'Price + CTA card',
        subtitle: 'Simple product image with clear order-now CTA',
        key: _ctaCardKey,
        filename: 'sellhub_cta_share.png',
        layout: _ShareVisualLayout.cta,
      ),
    ];
  }

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _duplicateOfferWithEditedPrice(_SocialShareModel model) async {
    final controller = TextEditingController(text: '${model.recommendedPrice}');
    final customCopy = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Duplicate offer with edited price'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Offer price',
              hintText: 'Set seller-facing offer price',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final price = int.tryParse(controller.text.trim()) ?? 0;
                if (price <= 0) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(
                  'Special offer\n${model.title}\nOffer price: ৳$price\nOrder now by sending name, address, and phone number.\n${model.link}',
                );
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
    if (customCopy == null || customCopy.trim().isEmpty) return;
    await _copyText(customCopy, 'Custom offer copy copied.');
  }

  Future<void> _shareImageCard({
    required GlobalKey key,
    required String filename,
    required String shareText,
  }) async {
    setState(() {
      _sharingImage = true;
    });
    try {
      final bytes = await _captureKeyAsPng(key);
      if (bytes == null) return;
      await Share.shareXFiles(
        <XFile>[XFile.fromData(bytes, mimeType: 'image/png', name: filename)],
        text: shareText,
        subject: 'SellHub share card',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sharingImage = false;
        });
      }
    }
  }

  Future<Uint8List?> _captureKeyAsPng(GlobalKey key) async {
    final context = key.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.model});

  final _SocialShareModel model;

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
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColor.safe1,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColor.safe),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AppNetworkImage(
                imageUrl: model.imageUrl,
                fit: BoxFit.cover,
                backgroundColor: AppColor.safe1,
                icon: HugeIcons.strokeRoundedPackageSearch01,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColor.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${model.brand} • ${model.storeTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(label: 'Base ৳${model.basePrice}'),
                    _MetaPill(label: 'Recommended ৳${model.recommendedPrice}'),
                    _MetaPill(label: 'Safe margin ৳${model.safeMargin}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingGuide extends StatelessWidget {
  const _PricingGuide({required this.model});

  final _SocialShareModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller pricing guide',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PricePill(label: 'Min sell', value: '৳${model.minSellPrice}'),
              _PricePill(
                label: 'Recommended',
                value: '৳${model.recommendedPrice}',
              ),
              _PricePill(label: 'Premium', value: '৳${model.premiumPrice}'),
              _PricePill(
                label: 'Margin window',
                value: '৳${model.minMargin} - ৳${model.maxMargin}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyVariantCard extends StatelessWidget {
  const _CopyVariantCard({
    required this.variant,
    required this.onCopy,
    required this.onShare,
  });

  final _SocialCopyVariant variant;
  final VoidCallback onCopy;
  final VoidCallback onShare;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  variant.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MetaPill(label: variant.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            variant.body,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ShareActionButton(
                  icon: HugeIcons.strokeRoundedCopy01,
                  label: 'Copy',
                  onTap: onCopy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareActionButton(
                  icon: HugeIcons.strokeRoundedShare08,
                  label: 'Share',
                  primary: true,
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageVariantTile extends StatelessWidget {
  const _ImageVariantTile({
    required this.title,
    required this.subtitle,
    required this.boundaryKey,
    required this.onShare,
    required this.child,
  });

  final String title;
  final String subtitle;
  final GlobalKey boundaryKey;
  final VoidCallback? onShare;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
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
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RepaintBoundary(key: boundaryKey, child: child),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _ShareActionButton(
              icon: HugeIcons.strokeRoundedShare08,
              label: 'Share image',
              primary: true,
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareVisualCard extends StatelessWidget {
  const _ShareVisualCard({required this.model, required this.layout});

  final _SocialShareModel model;
  final _ShareVisualLayout layout;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(24);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AppNetworkImage(
        imageUrl: model.imageUrl,
        fit: BoxFit.cover,
        backgroundColor: AppColor.safe1,
        icon: HugeIcons.strokeRoundedPackageSearch01,
      ),
    );

    switch (layout) {
      case _ShareVisualLayout.square:
        return Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFF8FBFB), Color(0xFFE4F1F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColor.safe),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: image),
              const SizedBox(height: 12),
              Text(
                model.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order now ৳${model.recommendedPrice}',
                style: const TextStyle(
                  color: AppColor.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                model.shortEnglishPitch,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const _CardFooter(),
            ],
          ),
        );
      case _ShareVisualLayout.story:
        return Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF163E41), Color(0xFF2C6A6D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: AppColor.safe),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start selling instantly',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: image),
              const SizedBox(height: 12),
              Text(
                model.shortBanglaPitch,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '৳${model.recommendedPrice}',
                        style: const TextStyle(
                          color: AppColor.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const Text(
                      'Inbox to order',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _ShareVisualLayout.cta:
        return Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.white,
            border: Border.all(color: AppColor.safe),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: image),
              const SizedBox(height: 12),
              Text(
                model.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                model.trustFocusedLine,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '৳${model.marginSafePrice}',
                      style: const TextStyle(
                        color: AppColor.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.brandWarm,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Order now',
                      style: TextStyle(
                        color: AppColor.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColor.brandWarm,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'SellHub',
            style: TextStyle(color: AppColor.text, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Sell from your phone. We handle the rest.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColor.safe1,
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppHugeIcon(icon, size: 18, color: AppColor.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
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

class _ShareActionButton extends StatelessWidget {
  const _ShareActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFDFF55A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary ? const Color(0xFFDFF55A) : AppColor.safe,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppHugeIcon(
              icon,
              size: 16,
              color: primary ? AppColor.text : AppColor.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: primary ? AppColor.text : AppColor.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialShareModel {
  const _SocialShareModel({
    required this.storeTitle,
    required this.title,
    required this.brand,
    required this.imageUrl,
    required this.link,
    required this.basePrice,
    required this.minSellPrice,
    required this.recommendedPrice,
    required this.premiumPrice,
    required this.marginSafePrice,
    required this.minMargin,
    required this.maxMargin,
    required this.safeMargin,
    required this.shortBanglaPitch,
    required this.shortEnglishPitch,
    required this.trustFocusedLine,
    required this.orderNowTemplate,
  });

  final String storeTitle;
  final String title;
  final String brand;
  final String imageUrl;
  final String link;
  final int basePrice;
  final int minSellPrice;
  final int recommendedPrice;
  final int premiumPrice;
  final int marginSafePrice;
  final int minMargin;
  final int maxMargin;
  final int safeMargin;
  final String shortBanglaPitch;
  final String shortEnglishPitch;
  final String trustFocusedLine;
  final String orderNowTemplate;

  factory _SocialShareModel.fromProduct({
    required ActiveStore store,
    required ProductResCommon product,
    required String link,
  }) {
    final title = product.translation?.trim().isNotEmpty == true
        ? product.translation!.trim()
        : product.title?.trim().isNotEmpty == true
        ? product.title!.trim()
        : 'Product';
    final brand = product.brands.isNotEmpty
        ? product.brands.first.trim()
        : store.title;
    final normalizedBrand = (brand ?? '').trim();
    final imageUrl = product.thumbnail?.trim().isNotEmpty == true
        ? product.thumbnail!.trim()
        : product.images.isNotEmpty
        ? product.images.first.image?.trim() ?? ''
        : '';
    final basePrice = (product.price ?? 0).round();
    final minSellPrice = ((product.minResellPrice ?? product.price ?? 0))
        .round();
    final maxSellPrice =
        ((product.maxResellPrice ??
                product.minResellPrice ??
                product.price ??
                0))
            .round();
    final recommendedPrice = _recommendedSellPrice(
      basePrice: basePrice,
      minSellPrice: minSellPrice,
      maxSellPrice: maxSellPrice,
    );
    final premiumPrice = maxSellPrice > 0 ? maxSellPrice : recommendedPrice;
    final marginSafePrice = recommendedPrice;
    final minMargin = (minSellPrice - basePrice).clamp(0, 1 << 30);
    final maxMargin = (premiumPrice - basePrice).clamp(0, 1 << 30);
    final safeMargin = (marginSafePrice - basePrice).clamp(0, 1 << 30);
    final shortBanglaPitch =
        'ঘরে বসে অর্ডার নিন। ${title.length > 34 ? '${title.substring(0, 34)}...' : title} এখন মাত্র ৳$recommendedPrice।';
    final shortEnglishPitch =
        'Easy sell item from $brand. Clean margin, trusted supply, and quick order handling.';
    final trustFocusedLine =
        'Trusted supplier, simple delivery flow, and reseller-friendly payout setup.';
    final orderNowTemplate = StringBuffer()
      ..writeln('Assalamu Alaikum,')
      ..writeln(title)
      ..writeln('Price: ৳$recommendedPrice')
      ..writeln('To order, send your name, address, and phone number.')
      ..writeln(link);

    return _SocialShareModel(
      storeTitle: store.title ?? 'Supplier store',
      title: title,
      brand: normalizedBrand.isEmpty ? 'Trusted supplier' : normalizedBrand,
      imageUrl: imageUrl,
      link: link,
      basePrice: basePrice,
      minSellPrice: minSellPrice,
      recommendedPrice: recommendedPrice,
      premiumPrice: premiumPrice,
      marginSafePrice: marginSafePrice,
      minMargin: minMargin,
      maxMargin: maxMargin,
      safeMargin: safeMargin,
      shortBanglaPitch: shortBanglaPitch,
      shortEnglishPitch: shortEnglishPitch,
      trustFocusedLine: trustFocusedLine,
      orderNowTemplate: orderNowTemplate.toString(),
    );
  }
}

class _SocialCopyVariant {
  const _SocialCopyVariant({
    required this.title,
    required this.label,
    required this.body,
    required this.copyToast,
  });

  final String title;
  final String label;
  final String body;
  final String copyToast;
}

class _ImageVariant {
  const _ImageVariant({
    required this.title,
    required this.subtitle,
    required this.key,
    required this.filename,
    required this.layout,
  });

  final String title;
  final String subtitle;
  final GlobalKey key;
  final String filename;
  final _ShareVisualLayout layout;
}

enum _ShareVisualLayout { square, story, cta }

List<_SocialCopyVariant> _buildCopyVariants(_SocialShareModel model) {
  return <_SocialCopyVariant>[
    _SocialCopyVariant(
      title: 'WhatsApp sell copy',
      label: 'WhatsApp',
      body:
          'Assalamu Alaikum,\n${model.title}\nআজকের সেলিং প্রাইস ৳${model.recommendedPrice}\n${model.shortBanglaPitch}\nঅর্ডার করতে নাম, ঠিকানা, ফোন নাম্বার দিন।\n${model.link}',
      copyToast: 'WhatsApp sell copy copied.',
    ),
    _SocialCopyVariant(
      title: 'Facebook caption',
      label: 'Facebook',
      body:
          'New arrival from ${model.brand}\n${model.title}\nPrice: ৳${model.recommendedPrice}\n${model.shortEnglishPitch}\nInbox to order.\n${model.link}',
      copyToast: 'Facebook caption copied.',
    ),
    _SocialCopyVariant(
      title: 'Short Bangla pitch',
      label: 'Bangla',
      body:
          '${model.shortBanglaPitch}\nপ্রাইস: ৳${model.recommendedPrice}\nঅর্ডার করতে ইনবক্স করুন।',
      copyToast: 'Bangla pitch copied.',
    ),
    _SocialCopyVariant(
      title: 'Short English pitch',
      label: 'English',
      body:
          '${model.title}\nPrice: ৳${model.recommendedPrice}\n${model.shortEnglishPitch}\nMessage now to order.',
      copyToast: 'English pitch copied.',
    ),
    _SocialCopyVariant(
      title: 'Urgency version',
      label: 'Urgency',
      body:
          'Fast moving item\n${model.title}\nToday only at ৳${model.recommendedPrice}\nLimited order slots. Confirm early.\n${model.link}',
      copyToast: 'Urgency copy copied.',
    ),
    _SocialCopyVariant(
      title: 'Trust-focused version',
      label: 'Trust',
      body:
          '${model.title}\nPrice: ৳${model.recommendedPrice}\n${model.trustFocusedLine}\nSafe order process and delivery support.\n${model.link}',
      copyToast: 'Trust-focused copy copied.',
    ),
    _SocialCopyVariant(
      title: 'Margin-safe price version',
      label: 'Safe margin',
      body:
          '${model.title}\nSeller-safe price: ৳${model.marginSafePrice}\nThis keeps reseller margin clear while staying buyer-friendly.\nOrder now:\n${model.link}',
      copyToast: 'Margin-safe copy copied.',
    ),
    _SocialCopyVariant(
      title: 'Order now template',
      label: 'Order',
      body: model.orderNowTemplate,
      copyToast: 'Order-now message copied.',
    ),
  ];
}

int _recommendedSellPrice({
  required int basePrice,
  required int minSellPrice,
  required int maxSellPrice,
}) {
  if (minSellPrice > 0 && maxSellPrice > 0 && maxSellPrice >= minSellPrice) {
    return ((minSellPrice + maxSellPrice) / 2).round();
  }
  if (minSellPrice > 0) return minSellPrice;
  if (maxSellPrice > 0) return maxSellPrice;
  return basePrice > 0 ? basePrice : 0;
}
