import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/product_viability/product_viability.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_helpers.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_widgets.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class SupplyIntelligencePreview extends StatelessWidget {
  const SupplyIntelligencePreview({
    super.key,
    required this.profile,
    this.product,
  });

  final SupplierTrustProfile profile;
  final ProductResCommon? product;

  @override
  Widget build(BuildContext context) {
    final signals = _buildSignals(profile: profile, product: product);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SupplierTrustScoreBadge(score: profile.score, compact: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _summaryLine(profile),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: signals
              .map(
                (signal) => _SupplySignalPill(
                  label: signal.label,
                  color: signal.color,
                  backgroundColor: signal.backgroundColor,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class SupplyIntelligenceCommitCard extends StatelessWidget {
  const SupplyIntelligenceCommitCard({
    super.key,
    required this.profile,
    required this.product,
  });

  final SupplierTrustProfile profile;
  final ProductResCommon product;

  @override
  Widget build(BuildContext context) {
    final viability = ProductViabilityEngine.build(product);
    final signals = _buildSignals(profile: profile, product: product);
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
            'Supply intelligence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Commit only after supplier trust and product sellability look strong together.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                label: 'Trust score',
                value: '${profile.score.round()}',
              ),
              _MetricPill(
                label: 'Band',
                value: supplierTrustBandStyleForScore(profile.score).label,
              ),
              _MetricPill(
                label: 'Fulfillment',
                value: formatTrustPercent(profile.fulfillmentSuccessRate),
              ),
              _MetricPill(
                label: 'Returns',
                value: formatTrustPercent(profile.returnRate),
              ),
              _MetricPill(
                label: 'Payout',
                value: profile.paysResellersOnTime == true
                    ? 'On time'
                    : profile.paysResellersOnTime == false
                    ? 'Needs review'
                    : 'Unknown',
              ),
              _MetricPill(
                label: '30d activity',
                value: formatTrustCount(profile.shippedOrders30d),
              ),
              _MetricPill(
                label: 'Demand',
                value: '${viability.demandScore.round()}',
              ),
              _MetricPill(
                label: 'Shareability',
                value: '${viability.shareabilityScore.round()}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: signals
                .map(
                  (signal) => _SupplySignalPill(
                    label: signal.label,
                    color: signal.color,
                    backgroundColor: signal.backgroundColor,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColor.safe1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplySignalPill extends StatelessWidget {
  const _SupplySignalPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SupplySignal {
  const _SupplySignal({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
}

String _summaryLine(SupplierTrustProfile profile) {
  final parts = <String>[
    '${formatTrustPercent(profile.fulfillmentSuccessRate)} fulfilled',
    '${formatTrustPercent(profile.returnRate)} returns',
    '${formatTrustCount(profile.shippedOrders30d)} in 30d',
  ].where((item) => !item.contains('--')).toList(growable: false);
  if (parts.isEmpty) {
    return supplierTrustBandStyleForScore(profile.score).description;
  }
  return parts.join(' • ');
}

List<_SupplySignal> _buildSignals({
  required SupplierTrustProfile profile,
  required ProductResCommon? product,
}) {
  final signals = <_SupplySignal>[];
  final band = supplierTrustBandStyleForScore(profile.score);
  signals.add(
    _SupplySignal(
      label: band.label,
      color: band.color,
      backgroundColor: band.softColor,
    ),
  );
  if (profile.verified) {
    signals.add(
      const _SupplySignal(
        label: 'Verified supplier',
        color: AppColor.primary,
        backgroundColor: AppColor.primarySoft,
      ),
    );
  }
  if (profile.paysResellersOnTime == true) {
    signals.add(
      const _SupplySignal(
        label: 'Payout reliable',
        color: AppColor.green,
        backgroundColor: Color(0xFFEAF8F1),
      ),
    );
  } else if (profile.paysResellersOnTime == false) {
    signals.add(
      const _SupplySignal(
        label: 'Payout needs review',
        color: AppColor.warning,
        backgroundColor: AppColor.warningLight,
      ),
    );
  }
  if (profile.topCategories.isNotEmpty) {
    signals.add(
      _SupplySignal(
        label: 'Top: ${profile.topCategories.take(2).join(', ')}',
        color: AppColor.neutral2,
        backgroundColor: Colors.white,
      ),
    );
  }
  if (profile.shippedOrders30d != null) {
    final active = profile.shippedOrders30d! >= 120;
    signals.add(
      _SupplySignal(
        label: active ? 'High 30d activity' : 'Moderate 30d activity',
        color: active ? AppColor.green : AppColor.info,
        backgroundColor: active ? const Color(0xFFEAF8F1) : AppColor.infoLight,
      ),
    );
  }
  if (product != null) {
    final viability = ProductViabilityEngine.build(product);
    signals.add(
      _SupplySignal(
        label:
            'Sellability ${viability.demandScore.round()}/${viability.shareabilityScore.round()}',
        color: AppColor.primary,
        backgroundColor: AppColor.safe1,
      ),
    );
    for (final label in viability.labels.take(2)) {
      signals.add(
        _SupplySignal(
          label: label,
          color: AppColor.text,
          backgroundColor: Colors.white,
        ),
      );
    }
  }
  return signals;
}
