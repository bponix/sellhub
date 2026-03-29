import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sellhub/core/constants/app_color.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = 14,
    this.margin,
    this.tinted = false,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final child = Shimmer.fromColors(
      baseColor: tinted ? AppColor.safe2 : AppColor.safe1,
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: tinted ? AppColor.safe2 : AppColor.safe1,
          borderRadius: BorderRadius.circular(radius),
          border: tinted
              ? Border.all(color: AppColor.safe.withValues(alpha: 0.85))
              : null,
        ),
      ),
    );

    if (margin == null) return child;
    return Padding(padding: margin!, child: child);
  }
}

class AppSkeletonCard extends StatelessWidget {
  const AppSkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColor.safe),
      ),
      child: child,
    );
  }
}
