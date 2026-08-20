import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:hugeicons/hugeicons.dart';

class categoryTextSeeAll extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const categoryTextSeeAll({super.key, this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: const AppHugeIcon(
            HugeIcons.strokeRoundedGridView,
            size: 16,
            color: AppColor.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColor.text,
            ),
          ),
        ),
        if (onTap != null) const SizedBox(width: 8),
        if (onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.safe1,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColor.safe),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 4),
                  AppHugeIcon(
                    HugeIcons.strokeRoundedArrowRight02,
                    size: 14,
                    color: AppColor.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
