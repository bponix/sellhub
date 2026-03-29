import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widget/app_huge_icon.dart';

class CustomerReviewLineDraw extends StatelessWidget {
  final String number;
  final double percent;
  final bool isEnable;
  const CustomerReviewLineDraw({
    super.key,
    required this.number,
    required this.percent,
    required this.isEnable,
  });

  @override
  Widget build(BuildContext context) {
    final progress = percent.clamp(0.0, 1.0);
    final activeColor = isEnable ? AppColor.primary : AppColor.neutral1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEnable ? AppColor.safe1.withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColor.text.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          AppHugeIcon(
            HugeIcons.strokeRoundedStar,
            size: 15,
            color: activeColor,
            secondaryColor: isEnable
                ? AppColor.primary.withValues(alpha: 0.18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: AppColor.safe,
                borderRadius: BorderRadius.circular(999),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
