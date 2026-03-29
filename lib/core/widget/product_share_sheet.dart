import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_huge_icon.dart';

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
    final shareText = SellHubShareLinkBuilder.buildProductShareText(
      store: store,
      product: product,
      referCode: referCode,
    );
    final title = product.translation?.trim().isNotEmpty == true
        ? product.translation!.trim()
        : product.title?.trim().isNotEmpty == true
        ? product.title!.trim()
        : 'Product';
    final brand = product.brands.isNotEmpty
        ? product.brands.first.trim()
        : store.title;
    final imageUrl = product.thumbnail?.trim().isNotEmpty == true
        ? product.thumbnail!.trim()
        : product.images.isNotEmpty
        ? product.images.first.image?.trim()
        : null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductShareSheetBody(
        title: title,
        brand: brand,
        imageUrl: imageUrl,
        price: product.price?.round(),
        link: link,
        shareText: shareText,
      ),
    );
  }
}

class _ProductShareSheetBody extends StatelessWidget {
  const _ProductShareSheetBody({
    required this.title,
    required this.brand,
    required this.imageUrl,
    required this.price,
    required this.link,
    required this.shareText,
  });

  final String title;
  final String? brand;
  final String? imageUrl;
  final int? price;
  final String link;
  final String shareText;

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AppNetworkImage(
                      imageUrl: imageUrl,
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
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColor.text,
                            ),
                      ),
                      if ((brand ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColor.neutral2,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      if ((price ?? 0) > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '৳$price',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColor.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColor.safe),
              ),
              child: Text(
                link,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedCopy01,
                    label: 'Copy link',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product link copied.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedShare08,
                    label: 'Share product',
                    primary: true,
                    onTap: () {
                      Share.share(shareText, subject: title);
                    },
                  ),
                ),
              ],
            ),
          ],
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
  final VoidCallback onTap;
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
