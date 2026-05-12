import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/utils/convertBengaliNumber.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class SellingIntelligenceCard extends StatelessWidget {
  const SellingIntelligenceCard({
    super.key,
    required this.product,
    required this.pricing,
  });

  final ProductResCommon product;
  final SmartPricingProfile pricing;

  @override
  Widget build(BuildContext context) {
    final intelligence = SellingIntelligenceEngine.build(
      product: product,
      pricing: pricing,
    );

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
            'Selling intelligence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use guided pricing and channel fit instead of guessing how to pitch this product.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _PriceBandSummary(intelligence: intelligence),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SignalPill(
                label:
                    'Best channel ${intelligence.bestChannelLabel}',
                tone: AppColor.primary,
                background: AppColor.primarySoft,
              ),
              _SignalPill(
                label:
                    'Demand ${intelligence.viability.demandScore.round()}/100',
              ),
              _SignalPill(
                label: intelligence.repeatPotentialLabel,
              ),
              _SignalPill(
                label: intelligence.trustRiskLabel,
                tone: intelligence.trustRiskColor,
                background: intelligence.trustRiskSoftColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: intelligence.priceLadders
                .map(
                  (option) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == intelligence.priceLadders.last ? 0 : 8,
                      ),
                      child: _PriceOptionCard(option: option),
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

class SellingIntelligenceCompactSummary extends StatelessWidget {
  const SellingIntelligenceCompactSummary({
    super.key,
    required this.product,
    required this.pricing,
    required this.selectedPrice,
  });

  final ProductResCommon product;
  final SmartPricingProfile pricing;
  final int selectedPrice;

  @override
  Widget build(BuildContext context) {
    final intelligence = SellingIntelligenceEngine.build(
      product: product,
      pricing: pricing,
    );
    final selectedMargin = selectedPrice - intelligence.basePrice;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selling intelligence',
            style: TextStyle(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _PriceBandSummary(intelligence: intelligence, compact: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SignalPill(
                label: 'Selected margin ৳${convertToBengaliNumber(selectedMargin)}',
              ),
              _SignalPill(label: 'Best channel ${intelligence.bestChannelLabel}'),
              _SignalPill(label: intelligence.repeatPotentialLabel),
              _SignalPill(
                label: intelligence.trustRiskLabel,
                tone: intelligence.trustRiskColor,
                background: intelligence.trustRiskSoftColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SellingIntelligenceEngine {
  const SellingIntelligenceEngine._();

  static SellingIntelligenceProfile build({
    required ProductResCommon product,
    required SmartPricingProfile pricing,
  }) {
    final viability = ProductViabilityEngine.build(product);
    final bestChannel = _bestChannelFit(viability);
    final repeatPotentialLabel =
        viability.labels.contains('High repeat potential')
        ? 'High repeat potential'
        : viability.labels.contains('Beginner friendly')
        ? 'Steady repeat potential'
        : 'Moderate repeat potential';
    final trustRisk = _trustRisk(viability);
    return SellingIntelligenceProfile(
      basePrice:
          product.wholesalePrice?.round() ?? product.price?.round() ?? 0,
      viability: viability,
      bestChannelLabel: bestChannel.label,
      bestChannelReason: bestChannel.reason,
      repeatPotentialLabel: repeatPotentialLabel,
      trustRiskLabel: trustRisk.label,
      trustRiskColor: trustRisk.color,
      trustRiskSoftColor: trustRisk.softColor,
      priceLadders: [
        SellingIntelligencePriceLadder(
          label: 'Safe',
          price: pricing.minimumSafePrice,
          expectedMargin: pricing.minimumSafeMargin,
          note: 'Protect margin floor',
        ),
        SellingIntelligencePriceLadder(
          label: 'Recommended',
          price: pricing.recommendedPrice,
          expectedMargin: pricing.recommendedMargin,
          note: bestChannel.reason,
        ),
        SellingIntelligencePriceLadder(
          label: 'Premium',
          price: pricing.premiumPrice,
          expectedMargin: pricing.premiumMargin,
          note: 'Best for warm buyers',
        ),
      ],
      realisticMinPrice: pricing.realisticMinPrice,
      realisticMaxPrice: pricing.realisticMaxPrice,
      recommendedMargin: pricing.recommendedMargin,
    );
  }
}

class SellingIntelligenceProfile {
  const SellingIntelligenceProfile({
    required this.basePrice,
    required this.viability,
    required this.bestChannelLabel,
    required this.bestChannelReason,
    required this.repeatPotentialLabel,
    required this.trustRiskLabel,
    required this.trustRiskColor,
    required this.trustRiskSoftColor,
    required this.priceLadders,
    required this.realisticMinPrice,
    required this.realisticMaxPrice,
    required this.recommendedMargin,
  });

  final int basePrice;
  final ProductViabilityProfile viability;
  final String bestChannelLabel;
  final String bestChannelReason;
  final String repeatPotentialLabel;
  final String trustRiskLabel;
  final Color trustRiskColor;
  final Color trustRiskSoftColor;
  final List<SellingIntelligencePriceLadder> priceLadders;
  final int realisticMinPrice;
  final int realisticMaxPrice;
  final int recommendedMargin;
}

class SellingIntelligencePriceLadder {
  const SellingIntelligencePriceLadder({
    required this.label,
    required this.price,
    required this.expectedMargin,
    required this.note,
  });

  final String label;
  final int price;
  final int expectedMargin;
  final String note;
}

class _PriceBandSummary extends StatelessWidget {
  const _PriceBandSummary({
    required this.intelligence,
    this.compact = false,
  });

  final SellingIntelligenceProfile intelligence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Realistic conversion band ৳${convertToBengaliNumber(intelligence.realisticMinPrice)} - ৳${convertToBengaliNumber(intelligence.realisticMaxPrice)}',
            style: const TextStyle(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recommended margin ৳${convertToBengaliNumber(intelligence.recommendedMargin)} • Best fit: ${intelligence.bestChannelLabel} • ${intelligence.bestChannelReason}',
            style: const TextStyle(
              color: AppColor.neutral2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceOptionCard extends StatelessWidget {
  const _PriceOptionCard({required this.option});

  final SellingIntelligencePriceLadder option;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            option.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '৳${convertToBengaliNumber(option.price)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Margin ৳${convertToBengaliNumber(option.expectedMargin)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.green,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            option.note,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelFit {
  const _ChannelFit({required this.label, required this.reason});

  final String label;
  final String reason;
}

class _TrustRisk {
  const _TrustRisk({
    required this.label,
    required this.color,
    required this.softColor,
  });

  final String label;
  final Color color;
  final Color softColor;
}

_ChannelFit _bestChannelFit(ProductViabilityProfile profile) {
  if (profile.shareabilityScore >= 80) {
    return const _ChannelFit(
      label: 'Facebook post',
      reason: 'High shareability and broad public appeal.',
    );
  }
  if (profile.labels.contains('Beginner friendly')) {
    return const _ChannelFit(
      label: 'WhatsApp quick sell',
      reason: 'Low-friction chat selling with safer price acceptance.',
    );
  }
  if (profile.labels.contains('High repeat potential')) {
    return const _ChannelFit(
      label: 'COD-first',
      reason: 'Repeat-friendly category with easier price tolerance.',
    );
  }
  return const _ChannelFit(
    label: 'Premium buyer',
    reason: 'Needs warmer buyer intent to hold the higher price.',
  );
}

_TrustRisk _trustRisk(ProductViabilityProfile profile) {
  if (profile.trustScore >= 75 &&
      profile.deliveryRisk != ViabilityRiskLevel.high) {
    return const _TrustRisk(
      label: 'Low trust risk',
      color: AppColor.green,
      softColor: Color(0xFFEAF8F1),
    );
  }
  if (profile.trustScore >= 60) {
    return const _TrustRisk(
      label: 'Manageable trust risk',
      color: AppColor.info,
      softColor: AppColor.infoLight,
    );
  }
  return const _TrustRisk(
    label: 'High trust risk',
    color: AppColor.warning,
    softColor: AppColor.warningLight,
  );
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.label,
    this.tone = AppColor.text,
    this.background = AppColor.safe1,
  });

  final String label;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: tone,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
