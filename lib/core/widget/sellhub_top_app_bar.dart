import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';

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
  });

  final String title;
  final List<List<dynamic>> icon;
  final String? subtitle;
  final bool showSubtitle;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Size get preferredSize =>
      Size.fromHeight(64 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = showSubtitle && (subtitle?.trim().isNotEmpty ?? false)
        ? subtitle!.trim()
        : null;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.safe),
                    ),
                    alignment: Alignment.center,
                    child: const AppHugeIcon(
                      HugeIcons.strokeRoundedArrowLeft01,
                      size: 16,
                      color: AppColor.text,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 6),
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
                    style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                          color: AppColor.text,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ) ??
                        const TextStyle(
                          color: AppColor.text,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                  ),
                  if (resolvedSubtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      resolvedSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.0,
                          ),
                    ),
                  ] else if (!showBackButton) ...[
                    const SizedBox(height: 1),
                    Text(
                      'Resell from top suppliers',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.0,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (actions != null)
              ...actions!.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: action,
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: _SellHubAssetLogo(),
            ),
          ],
        ),
      ),
      actions: [
        const SizedBox.shrink(),
      ],
      bottom: bottom ??
          const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppColor.safe),
          ),
    );
  }
}

class _SellHubAssetLogo extends StatelessWidget {
  const _SellHubAssetLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.safe),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/sellhub_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const AppHugeIcon(
            HugeIcons.strokeRoundedShoppingBag03,
            size: 18,
            color: AppColor.primary,
          ),
        ),
      ),
    );
  }
}
