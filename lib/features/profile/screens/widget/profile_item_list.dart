import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/widget/app_huge_icon.dart';

class ItemListWidget extends StatelessWidget {
  final List<String> items; // data list
  final int selectedIndex; // which index select currently
  final Function(int) onTabSelected;

  const ItemListWidget({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IntrinsicWidth(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.safe1 : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColor.primary : AppColor.safe,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppHugeIcon(
                        _iconForLabel(items[index]),
                        size: 15,
                        color: isSelected
                            ? AppColor.primary
                            : AppColor.neutral2,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        items[index],
                        style: TextStyle(
                          color: isSelected
                              ? AppColor.primary
                              : AppColor.text,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<List<dynamic>> _iconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return HugeIcons.strokeRoundedHome03;
      case 'order':
        return HugeIcons.strokeRoundedInvoice03;
      case 'password':
        return HugeIcons.strokeRoundedLockPassword;
      case 'notifications':
        return HugeIcons.strokeRoundedNotificationSquare;
      case 'log out':
        return HugeIcons.strokeRoundedLogout02;
      default:
        return HugeIcons.strokeRoundedCircle;
    }
  }
}
