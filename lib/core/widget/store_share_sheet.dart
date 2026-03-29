import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/share/sellhub_share_link_builder.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class StoreShareSheet {
  const StoreShareSheet._();

  static Future<void> show(BuildContext context) async {
    final storefront = context.read<StorefrontCubit>().state;
    final activeStore = context.read<StoreContextCubit>().state.activeStore;

    final siteId = storefront.siteDetails?.id ?? activeStore?.siteId;
    final domain = storefront.siteDetails?.domain?.trim().isNotEmpty == true
        ? storefront.siteDetails!.domain!.trim()
        : activeStore?.domain.trim();

    if (siteId == null || domain == null || domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Current store link is unavailable right now.'),
          backgroundColor: AppColor.alert,
        ),
      );
      return;
    }

    final title = storefront.siteDetails?.title?.trim().isNotEmpty == true
        ? storefront.siteDetails!.title!.trim()
        : activeStore?.title?.trim();
    final logoUrl = storefront.siteDetails?.phoneLogo?.trim().isNotEmpty == true
        ? storefront.siteDetails!.phoneLogo!.trim()
        : activeStore?.logoUrl?.trim();

    final link = SellHubShareLinkBuilder.buildStoreUri(
      store: ActiveStore(
        siteId: siteId,
        domain: domain,
        title: title,
        logoUrl: logoUrl,
      ),
    ).toString();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StoreShareSheetBody(
        title: title?.isNotEmpty == true ? title! : domain,
        domain: domain,
        logoUrl: logoUrl,
        link: link,
      ),
    );
  }
}

class _StoreShareSheetBody extends StatelessWidget {
  const _StoreShareSheetBody({
    required this.title,
    required this.domain,
    required this.link,
    this.logoUrl,
  });

  final String title;
  final String domain;
  final String link;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColor.safe),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AppNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      backgroundColor: AppColor.safe1,
                      icon: HugeIcons.strokeRoundedStore03,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColor.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        domain,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColor.safe),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: 188,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      color: AppColor.text,
                      eyeShape: QrEyeShape.square,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: AppColor.text,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan or open this store link',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColor.safe),
              ),
              child: Text(
                link,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral3,
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
                        const SnackBar(content: Text('Store link copied.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ShareActionButton(
                    icon: HugeIcons.strokeRoundedShare08,
                    label: 'Share',
                    primary: true,
                    onTap: () {
                      Share.share('$title\n$link', subject: title);
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
          color: primary ? AppColor.primary : AppColor.safe1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primary ? AppColor.primary : AppColor.safe),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppHugeIcon(
              icon,
              size: 16,
              color: primary ? Colors.white : AppColor.primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.white : AppColor.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
