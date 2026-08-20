import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';

class SellHubBrandMark extends StatelessWidget {
  const SellHubBrandMark({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.wordmarkColor,
  });

  final double size;
  final bool showWordmark;
  final Color? wordmarkColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = wordmarkColor ?? AppColor.text;
    final badgeSize = size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final canShowWordmark =
            showWordmark &&
            (maxWidth.isInfinite || maxWidth >= badgeSize * 2.5);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(badgeSize * 0.28),
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(color: Colors.white),
                child: Image.asset(
                  'assets/sellhub_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (canShowWordmark) ...[
              SizedBox(width: size * 0.22),
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sell',
                        style: TextStyle(
                          color: labelColor,
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Hub',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontSize: size * 0.42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
