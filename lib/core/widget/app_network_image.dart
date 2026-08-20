import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';
import 'package:sellhub/core/widget/app_skeleton.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
    this.icon = HugeIcons.strokeRoundedImageNotFound02,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final List<List<dynamic>> icon;

  static const List<String> _knownBrokenImageMarkers = <String>[
    'default.png',
    'no-image',
    'no_image',
    'image-not-available',
    'image_not_available',
  ];

  String get _normalizedImageUrl => (imageUrl ?? '').trim();

  bool get _hasImage {
    if (_normalizedImageUrl.isEmpty) return false;
    final normalized = _normalizedImageUrl.toLowerCase();
    return !_knownBrokenImageMarkers.any(normalized.contains);
  }

  @override
  Widget build(BuildContext context) {
    final child = !_hasImage
        ? _FallbackImage(icon: icon, backgroundColor: backgroundColor)
        : CachedNetworkImage(
            imageUrl: _normalizedImageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => AppSkeleton(
              width: width,
              height: height ?? 100,
              radius: (borderRadius?.topLeft.x ?? 14),
              tinted: true,
            ),
            errorWidget: (_, __, ___) =>
                _FallbackImage(icon: icon, backgroundColor: backgroundColor),
          );

    Widget wrapped = child;
    if (padding != null) {
      wrapped = Padding(padding: padding!, child: wrapped);
    }
    if (borderRadius != null) {
      wrapped = ClipRRect(borderRadius: borderRadius!, child: wrapped);
    }
    return wrapped;
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.icon, this.backgroundColor});

  final List<List<dynamic>> icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight.isFinite && constraints.maxHeight < 64 ||
            constraints.maxWidth.isFinite && constraints.maxWidth < 64;
        final iconBoxSize = compact ? 30.0 : 38.0;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColor.safe1,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [backgroundColor ?? AppColor.safe1, Colors.white],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(compact ? 12 : 14),
                  border: Border.all(color: AppColor.safe),
                ),
                child: AppHugeIcon(
                  icon,
                  color: AppColor.neutral1,
                  size: compact ? 16 : 18,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                const Text(
                  'No image',
                  style: TextStyle(
                    color: AppColor.neutral2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
