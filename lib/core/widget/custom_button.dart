import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final String buttonName;
  final IconData? iconData;
  const CustomButton({
    super.key,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.buttonName,
    this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      buttonName,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: backgroundColor == Colors.white
              ? AppColor.safe
              : foregroundColor.withValues(alpha: 0.14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      child: iconData == null
          ? label
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 18),
                const SizedBox(width: 10),
                Flexible(child: label),
              ],
            ),
    );
  }
}
