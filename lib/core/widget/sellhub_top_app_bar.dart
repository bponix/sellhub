import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/store/store_context_cubit.dart';
import 'package:sellhub/core/utils/app_router.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_network_image.dart';
import 'package:sellhub/core/widget/store_share_sheet.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_cubit.dart';

class SellHubTopAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SellHubTopAppBar({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.showSubtitle = false,
    this.bottom,
    this.actions,
    this.showBackButton = false,
    this.showStoreActions = false,
  });

  final String title;
  final List<List<dynamic>> icon;
  final String? subtitle;
  final bool showSubtitle;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showStoreActions;

  @override
  Size get preferredSize =>
      Size.fromHeight(68 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final activeStore = context.read<StoreContextCubit>().state.activeStore;
    final storefrontState = context.watch<StorefrontCubit>().state;
    final site = storefrontState.siteDetails;
    final storeLogo = site?.favicon?.trim().isNotEmpty == true
        ? site!.favicon!.trim()
        : site?.phoneLogo?.trim().isNotEmpty == true
        ? site!.phoneLogo!.trim()
        : activeStore?.logoUrl;
    final showLeadingVisual = showStoreActions;
    final resolvedSubtitle = showSubtitle && (subtitle?.trim().isNotEmpty ?? false)
        ? subtitle!.trim()
        : null;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 68,
      titleSpacing: 14,
      title: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColor.safe),
                  ),
                  alignment: Alignment.center,
                  child: const AppHugeIcon(
                    HugeIcons.strokeRoundedArrowLeft01,
                    size: 18,
                    color: AppColor.text,
                  ),
                ),
              ),
            ),
          if (showLeadingVisual) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.safe),
              ),
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: storeLogo?.trim().isNotEmpty == true
                    ? AppNetworkImage(
                        imageUrl: storeLogo,
                        fit: BoxFit.cover,
                        backgroundColor: Colors.white,
                        icon: icon,
                      )
                    : AppHugeIcon(
                        icon,
                        size: 18,
                        color: AppColor.primary,
                      ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.1,
                    letterSpacing: 0.1,
                  ),
                ),
                if (resolvedSubtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    resolvedSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColor.neutral2,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.1,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (showStoreActions) ...[
          _ActionChip(
            onTap: () => StoreShareSheet.show(context),
            icon: HugeIcons.strokeRoundedShare08,
            semanticLabel: 'Share current store',
          ),
          const SizedBox(width: 6),
          _ActionChip(
            onTap: () => AppRouter.goToStoreSelector(context),
            icon: HugeIcons.strokeRoundedSquareArrowDataTransferHorizontal,
            semanticLabel: 'Switch store',
          ),
          const SizedBox(width: 6),
          _ActionChip(
            onTap: () => AppRouter.goToStoreScanner(context),
            icon: HugeIcons.strokeRoundedQrCode,
            semanticLabel: 'Scan store QR',
          ),
          const SizedBox(width: 8),
        ],
        ...?actions,
        const Padding(
          padding: EdgeInsets.only(right: 14, left: 2),
          child: _SellHubBrandMark(),
        ),
      ],
      bottom: bottom ??
          const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppColor.safe),
          ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.onTap,
    required this.icon,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final List<List<dynamic>> icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColor.safe),
        ),
        alignment: Alignment.center,
        child: AppHugeIcon(
          icon,
          size: 16,
          color: AppColor.primary,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}

class _SellHubBrandMark extends StatelessWidget {
  const _SellHubBrandMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Image.asset(
        'assets/sellhub_logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
