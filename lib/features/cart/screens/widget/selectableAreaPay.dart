import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/widget/app_huge_icon.dart';

class SelectableListAreaPay extends StatelessWidget {
  final int itemCount;
  final int selectedIndex;
  final Function(int index) onTap;
  final Widget Function(int index) titleBuilder;
  final Widget Function(int index) subtitleBuilder;
  final bool Function(int index) isSelected;
  final Widget? Function(int index)? trailingBuilder;

  const SelectableListAreaPay({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onTap,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.isSelected,
    this.trailingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final selected = isSelected(index);

        return Padding(
          padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 15),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? AppColor.safe1 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColor.primary : AppColor.safe,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => onTap(index),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: AppHugeIcon(
                selected
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : HugeIcons.strokeRoundedCircle,
                color: selected ? AppColor.primary : AppColor.neutral2,
              ),
              title: titleBuilder(index),
              subtitle: subtitleBuilder(index),
              trailing:
                  trailingBuilder?.call(index) ??
                  (selected
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColor.safe),
                          ),
                          child: const Text(
                            'Selected',
                            style: TextStyle(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        )
                      : null),
            ),
          ),
        );
      },
    );
  }
}
