import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_helpers.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';
import 'package:sellhub/core/widget/app_huge_icon.dart';

class SupplierTrustScoreBadge extends StatelessWidget {
  const SupplierTrustScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  final double score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyleForScore(score);
    final normalizedScore = score.clamp(0, 100).toStringAsFixed(0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: style.softColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHugeIcon(
            HugeIcons.strokeRoundedStar,
            size: compact ? 14 : 16,
            color: style.color,
          ),
          const SizedBox(width: 6),
          Text(
            normalizedScore,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: style.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierTrustBandBadge extends StatelessWidget {
  const SupplierTrustBandBadge({super.key, required this.band});

  final SupplierTrustBand band;

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyle(band);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.softColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: style.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SupplierTrustVerifiedBadge extends StatelessWidget {
  const SupplierTrustVerifiedBadge({
    super.key,
    this.label = 'Verified supplier',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppHugeIcon(
            HugeIcons.strokeRoundedCheckmarkCircle02,
            size: 14,
            color: AppColor.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColor.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierTrustCompactFacts extends StatelessWidget {
  const SupplierTrustCompactFacts({
    super.key,
    required this.profile,
  });

  final SupplierTrustProfile profile;

  @override
  Widget build(BuildContext context) {
    final facts = <String>[
      '${formatTrustPercent(profile.fulfillmentSuccessRate)} fulfilled',
      '${formatTrustDays(profile.averageDeliveryDays)} avg delivery',
      '${formatTrustPercent(profile.returnRate)} returns',
      '${formatTrustCount(profile.shippedOrders30d)} shipped / 30d',
      if (profile.updatedAt != null) _supplierTrustFreshnessLabel(profile.updatedAt),
    ].where((item) => !item.contains('--')).toList(growable: false);

    return Text(
      facts.isEmpty
          ? supplierTrustBandStyleForScore(profile.score).description
          : facts.join(' • '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColor.neutral2,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class SupplierTrustCompactBadges extends StatelessWidget {
  const SupplierTrustCompactBadges({
    super.key,
    required this.profile,
    this.limitCategories = 2,
  });

  final SupplierTrustProfile profile;
  final int limitCategories;

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyleForScore(profile.score);
    final categoryLabels = profile.topCategories
        .take(limitCategories)
        .map((item) => 'Top: $item')
        .toList(growable: false);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _CompactTrustPill(
          label: style.label,
          textColor: style.color,
          backgroundColor: style.softColor,
          borderColor: style.borderColor,
        ),
        if (profile.verified)
          const _CompactTrustPill(
            label: 'Verified supplier',
            textColor: AppColor.primary,
            backgroundColor: AppColor.primarySoft,
            borderColor: AppColor.primarySoft,
          ),
        if (profile.paysResellersOnTime == true)
          const _CompactTrustPill(
            label: 'Pays on time',
            textColor: AppColor.green,
            backgroundColor: Color(0xFFEAF8F1),
            borderColor: Color(0xFFCFE9DE),
          ),
        if (profile.paysResellersOnTime == false)
          const _CompactTrustPill(
            label: 'Payouts need review',
            textColor: AppColor.warning,
            backgroundColor: AppColor.warningLight,
            borderColor: Color(0xFFEBCF9C),
          ),
        if (profile.minimumIssueRate != null)
          _CompactTrustPill(
            label: 'Issue floor ${formatTrustPercent(profile.minimumIssueRate)}',
            textColor: (profile.minimumIssueRate ?? 100) <= 3
                ? AppColor.green
                : AppColor.warning,
            backgroundColor: (profile.minimumIssueRate ?? 100) <= 3
                ? const Color(0xFFEAF8F1)
                : AppColor.warningLight,
            borderColor: (profile.minimumIssueRate ?? 100) <= 3
                ? const Color(0xFFCFE9DE)
                : const Color(0xFFEBCF9C),
          ),
        if (profile.updatedAt != null)
          _CompactTrustPill(
            label: _supplierTrustFreshnessLabel(profile.updatedAt),
            textColor: _supplierTrustIsFresh(profile.updatedAt)
                ? AppColor.green
                : AppColor.warning,
            backgroundColor: _supplierTrustIsFresh(profile.updatedAt)
                ? const Color(0xFFEAF8F1)
                : AppColor.warningLight,
            borderColor: _supplierTrustIsFresh(profile.updatedAt)
                ? const Color(0xFFCFE9DE)
                : const Color(0xFFEBCF9C),
          ),
        ...categoryLabels.map(
          (label) => _CompactTrustPill(
            label: label,
            textColor: AppColor.neutral2,
            backgroundColor: Colors.white,
            borderColor: AppColor.safe,
          ),
        ),
      ],
    );
  }
}

class SupplierTrustMetricTile extends StatelessWidget {
  const SupplierTrustMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.safe),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColor.safe1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppHugeIcon(icon!, size: 14, color: AppColor.primary),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColor.neutral2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColor.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          if ((hint ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupplierTrustMetricsRow extends StatelessWidget {
  const SupplierTrustMetricsRow({super.key, required this.metrics});

  final List<SupplierTrustMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 0;
        final crossAxisCount = width >= 720
            ? 3
            : width >= 420
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: crossAxisCount == 1 ? 2.75 : 1.25,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: metrics
              .map(
                (metric) => SupplierTrustMetricTile(
                  label: metric.label,
                  value: metric.value,
                  hint: metric.hint,
                  icon: metric.icon,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class SupplierTrustMetricsCard extends StatelessWidget {
  const SupplierTrustMetricsCard({
    super.key,
    required this.profile,
    this.title = 'Supplier trust',
    this.subtitle,
  });

  final SupplierTrustProfile profile;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyleForScore(profile.score);
    final metrics = _buildMetrics(profile);
    final rawSubtitle = subtitle?.trim() ?? '';
    final resolvedSubtitle = rawSubtitle.isNotEmpty
        ? rawSubtitle
        : style.description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.softColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: style.borderColor),
                ),
                child: AppHugeIcon(
                  HugeIcons.strokeRoundedShield01,
                  size: 18,
                  color: style.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColor.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (resolvedSubtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        resolvedSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColor.neutral2,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SupplierTrustScoreBadge(score: profile.score),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SupplierTrustBandBadge(band: style.band),
              if (profile.verified) const SupplierTrustVerifiedBadge(),
              if (profile.paysResellersOnTime != null)
                _StatusBadge(
                  label: profile.paysResellersOnTime == true
                      ? 'Pays resellers on time'
                      : 'Payouts need review',
                  tone: profile.paysResellersOnTime == true
                      ? _BadgeTone.positive
                      : _BadgeTone.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SupplierTrustMetricsRow(metrics: metrics),
          if (profile.topCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Top categories supplied',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColor.neutral2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.topCategories
                  .take(6)
                  .map(
                    (category) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColor.safe),
                      ),
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColor.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if ((profile.note ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: style.borderColor),
              ),
              child: Text(
                profile.note!.trim(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColor.neutral2,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<SupplierTrustMetric> _buildMetrics(SupplierTrustProfile profile) {
    final metrics = supplierTrustMetricsForProfile(profile);
    return metrics
        .asMap()
        .entries
        .map(
          (entry) => entry.value.copyWith(
            icon: switch (entry.key) {
              0 => HugeIcons.strokeRoundedDeliveryTruck02,
              1 => HugeIcons.strokeRoundedClock01,
              2 => HugeIcons.strokeRoundedRefresh,
              3 => HugeIcons.strokeRoundedPackage01,
              _ => HugeIcons.strokeRoundedAlert02,
            },
          ),
        )
        .toList(growable: false);
  }
}

class SupplierTrustDecisionCard extends StatelessWidget {
  const SupplierTrustDecisionCard({
    super.key,
    required this.profile,
  });

  final SupplierTrustProfile profile;

  @override
  Widget build(BuildContext context) {
    final style = supplierTrustBandStyleForScore(profile.score);
    final returnRate = profile.returnRate ?? 0;
    final issueRate = profile.minimumIssueRate ?? 0;
    final slowDelivery = (profile.averageDeliveryDays ?? 0) >= 6;
    final payoutNeedsReview = profile.paysResellersOnTime == false;
    final watch = style.band == SupplierTrustBand.watchlist ||
        returnRate >= 10 ||
        issueRate >= 6 ||
        slowDelivery ||
        payoutNeedsReview;
    final title = watch ? 'Confirm before you push this supplier' : 'Supplier is safe to push now';
    final guidance = watch
        ? 'Use this supplier after buyer confirmation, careful COD handling, and a tighter delivery promise.'
        : 'This supplier looks stable enough for normal reseller flow and faster quote-to-order work.';
    final action = watch
        ? 'Share first, confirm buyer intent, then place supplier order.'
        : 'You can quote confidently and move to order after buyer confirmation.';
    final reasons = <String>[
      if (profile.updatedAt != null) _supplierTrustFreshnessLabel(profile.updatedAt),
      if ((profile.fulfillmentSuccessRate ?? 0) > 0)
        '${formatTrustPercent(profile.fulfillmentSuccessRate)} fulfilled',
      if (slowDelivery) '${formatTrustDays(profile.averageDeliveryDays)} delivery',
      if (returnRate > 0) '${formatTrustPercent(profile.returnRate)} returns',
      if (issueRate > 0) '${formatTrustPercent(profile.minimumIssueRate)} issue floor',
      if (payoutNeedsReview) 'Payout timing needs review',
      if (profile.paysResellersOnTime == true) 'Pays resellers on time',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.softColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: style.borderColor),
                ),
                child: AppHugeIcon(
                  watch
                      ? HugeIcons.strokeRoundedAlert02
                      : HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 16,
                  color: style.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColor.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guidance,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColor.neutral2,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.borderColor),
            ),
            child: Text(
              action,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: style.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasons
                  .map(
                    (reason) => _CompactTrustPill(
                      label: reason,
                      textColor: style.color,
                      backgroundColor: Colors.white,
                      borderColor: style.borderColor,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

String _supplierTrustFreshnessLabel(DateTime? updatedAt) {
  if (updatedAt == null) return 'Trust review pending';
  final age = DateTime.now().difference(updatedAt);
  if (age.inHours < 24) return 'Reviewed today';
  if (age.inDays < 7) return 'Reviewed this week';
  return 'Trust needs refresh';
}

bool _supplierTrustIsFresh(DateTime? updatedAt) {
  if (updatedAt == null) return false;
  return DateTime.now().difference(updatedAt).inDays < 7;
}

enum _BadgeTone { positive, warning }

class _CompactTrustPill extends StatelessWidget {
  const _CompactTrustPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == _BadgeTone.positive
        ? AppColor.green
        : AppColor.warning;
    final background = tone == _BadgeTone.positive
        ? const Color(0xFFEAF8F1)
        : AppColor.warningLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
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
