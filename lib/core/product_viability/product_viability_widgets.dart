import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class ProductViabilityCompactBlock extends StatelessWidget {
  const ProductViabilityCompactBlock({
    super.key,
    required this.product,
    this.maxLabels = 3,
  });

  final ProductResCommon product;
  final int maxLabels;

  @override
  Widget build(BuildContext context) {
    final profile = ProductViabilityEngine.build(product);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Base ৳${convertToBengaliNumber(profile.baseCost.round())} • Sell ৳${convertToBengaliNumber(profile.minSellPrice.round())}-${convertToBengaliNumber(profile.maxSellPrice.round())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Margin ৳${convertToBengaliNumber(profile.minMargin.round())}-${convertToBengaliNumber(profile.maxMargin.round())} • Demand ${profile.demandScore.round()} • Share ${profile.shareabilityScore.round()} • Trust ${profile.trustScore.round()} ${profile.supplierName}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: AppColor.neutral2,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SignalPill(
              label: 'Delivery ${viabilityRiskLabel(profile.deliveryRisk)}',
              textColor: viabilityRiskColor(profile.deliveryRisk),
              backgroundColor: viabilityRiskSoftColor(profile.deliveryRisk),
            ),
            _SignalPill(
              label:
                  'Return ${viabilityRiskLabel(profile.returnSensitivity)}',
              textColor: viabilityRiskColor(profile.returnSensitivity),
              backgroundColor: viabilityRiskSoftColor(
                profile.returnSensitivity,
              ),
            ),
            ...profile.labels.take(maxLabels).map(
              (label) => const _LabelPillBuilder().build(label),
            ),
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => ProductViabilityExplanationSheet.show(context, product),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              'Why this is recommended',
              style: textTheme.labelSmall?.copyWith(
                color: AppColor.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductViabilityDetailCard extends StatelessWidget {
  const ProductViabilityDetailCard({
    super.key,
    required this.product,
  });

  final ProductResCommon product;

  @override
  Widget build(BuildContext context) {
    final profile = ProductViabilityEngine.build(product);
    final textTheme = Theme.of(context).textTheme;
    final tiles = <_ViabilityTile>[
      _ViabilityTile(
        label: 'Base supplier cost',
        value: '৳ ${convertToBengaliNumber(profile.baseCost.round())}',
      ),
      _ViabilityTile(
        label: 'Allowed sell price',
        value:
            '৳ ${convertToBengaliNumber(profile.minSellPrice.round())}-${convertToBengaliNumber(profile.maxSellPrice.round())}',
      ),
      _ViabilityTile(
        label: 'Estimated margin window',
        value:
            '৳ ${convertToBengaliNumber(profile.minMargin.round())}-${convertToBengaliNumber(profile.maxMargin.round())}',
      ),
      _ViabilityTile(
        label: 'Demand signal',
        value: '${profile.demandScore.round()} ${profile.demandLabel}',
      ),
      _ViabilityTile(
        label: 'Shareability score',
        value: '${profile.shareabilityScore.round()} ${profile.shareabilityLabel}',
      ),
      _ViabilityTile(
        label: 'Supplier trust score',
        value: '${profile.trustScore.round()}',
      ),
      _ViabilityTile(
        label: 'Delivery risk signal',
        value: viabilityRiskLabel(profile.deliveryRisk),
      ),
      _ViabilityTile(
        label: 'Return sensitivity',
        value: viabilityRiskLabel(profile.returnSensitivity),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product viability',
            style: textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Reseller-first guidance to help you avoid weak products and pick items that are easier to close.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.labels
                .map((label) => const _LabelPillBuilder().build(label))
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: () =>
                  ProductViabilityExplanationSheet.show(context, product),
              child: const Text('Why this is recommended'),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: tiles
                .map(
                  (tile) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColor.safe1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Text(
                          tile.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColor.neutral2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tile.value,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColor.text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class ProductViabilityExplanationSheet extends StatelessWidget {
  const ProductViabilityExplanationSheet({
    super.key,
    required this.product,
  });

  final ProductResCommon product;

  static Future<void> show(BuildContext context, ProductResCommon product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => ProductViabilityExplanationSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProductViabilityEngine.build(product);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this product is recommended',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColor.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.title ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...profile.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.text,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViabilityTile {
  const _ViabilityTile({required this.label, required this.value});

  final String label;
  final String value;
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LabelPillBuilder {
  const _LabelPillBuilder();

  Widget build(String label) {
    Color textColor = AppColor.primary;
    Color backgroundColor = AppColor.primarySoft;
    if (label == 'Risky delivery zone' || label == 'Low trust supplier') {
      textColor = AppColor.alert;
      backgroundColor = AppColor.alertLight;
    } else if (label == 'Good margin' || label == 'Fast mover') {
      textColor = AppColor.green;
      backgroundColor = const Color(0xFFEAF8F1);
    } else if (label == 'Beginner friendly' ||
        label == 'High repeat potential') {
      textColor = AppColor.info;
      backgroundColor = AppColor.infoLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
