import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';

class AppHugeIcon extends StatelessWidget {
  const AppHugeIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.secondaryColor,
    this.strokeWidth,
    this.semanticLabel,
    this.enabled = true,
    this.useThemeColor = false,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
  });

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;
  final Color? secondaryColor;
  final double? strokeWidth;
  final String? semanticLabel;
  final bool enabled;
  final bool useThemeColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedSize = size.clamp(14.0, 32.0).toDouble();
    final resolvedStrokeWidth = strokeWidth ?? _strokeForSize(resolvedSize);
    final baseColor = useThemeColor
        ? theme.iconTheme.color ?? theme.colorScheme.onSurface
        : color ?? AppColor.text;
    final resolvedColor = enabled
        ? baseColor
        : baseColor.withValues(alpha: 0.42);
    final resolvedSecondaryColor = enabled
        ? secondaryColor
        : secondaryColor?.withValues(alpha: 0.32);

    final iconWidget = SizedBox.square(
      dimension: resolvedSize,
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: resolvedSize,
          color: resolvedColor,
          secondaryColor: resolvedSecondaryColor,
          strokeWidth: resolvedStrokeWidth,
        ),
      ),
    );

    final decoratedIcon = backgroundColor == null &&
            borderColor == null &&
            padding == null &&
            borderRadius == null
        ? iconWidget
        : Container(
            padding: padding ?? EdgeInsets.all(resolvedSize <= 18 ? 4 : 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                borderRadius ?? (resolvedSize <= 18 ? 10 : 14),
              ),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!),
            ),
            child: iconWidget,
          );

    return Semantics(
      label: semanticLabel,
      enabled: enabled,
      image: true,
      child: ExcludeSemantics(
        excluding: semanticLabel == null,
        child: decoratedIcon,
      ),
    );
  }

  double _strokeForSize(double iconSize) {
    if (iconSize <= 16) return 1.55;
    if (iconSize <= 20) return 1.7;
    if (iconSize <= 24) return 1.8;
    if (iconSize <= 28) return 1.95;
    return 2.05;
  }
}
