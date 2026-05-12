import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';

@immutable
class SupplierTrustBandStyle {
  const SupplierTrustBandStyle({
    required this.band,
    required this.label,
    required this.description,
    required this.color,
    required this.softColor,
    required this.borderColor,
  });

  final SupplierTrustBand band;
  final String label;
  final String description;
  final Color color;
  final Color softColor;
  final Color borderColor;
}

SupplierTrustBand supplierTrustBandForScore(num score) {
  final normalized = score.toDouble().clamp(0, 100);
  if (normalized >= 80) return SupplierTrustBand.strong;
  if (normalized >= 55) return SupplierTrustBand.stable;
  return SupplierTrustBand.watchlist;
}

String supplierTrustBandLabel(SupplierTrustBand band) {
  switch (band) {
    case SupplierTrustBand.strong:
      return 'Strong';
    case SupplierTrustBand.stable:
      return 'Stable';
    case SupplierTrustBand.watchlist:
      return 'Watchlist';
  }
}

SupplierTrustBandStyle supplierTrustBandStyleForScore(num score) {
  final band = supplierTrustBandForScore(score);
  return supplierTrustBandStyle(band);
}

SupplierTrustBandStyle supplierTrustBandStyle(SupplierTrustBand band) {
  return SupplierTrustBandStyle(
    band: band,
    label: supplierTrustBandLabel(band),
    description: supplierTrustBandDescriptor(band),
    color: supplierTrustBandColor(band),
    softColor: supplierTrustBandSoftColor(band),
    borderColor: supplierTrustBandColor(band).withValues(alpha: 0.2),
  );
}

Color supplierTrustBandColor(SupplierTrustBand band) {
  switch (band) {
    case SupplierTrustBand.strong:
      return AppColor.green;
    case SupplierTrustBand.stable:
      return AppColor.info;
    case SupplierTrustBand.watchlist:
      return AppColor.warning;
  }
}

Color supplierTrustBandSoftColor(SupplierTrustBand band) {
  switch (band) {
    case SupplierTrustBand.strong:
      return const Color(0xFFEAF8F1);
    case SupplierTrustBand.stable:
      return AppColor.infoLight;
    case SupplierTrustBand.watchlist:
      return AppColor.warningLight;
  }
}

String supplierTrustBandDescriptor(SupplierTrustBand band) {
  switch (band) {
    case SupplierTrustBand.strong:
      return 'High-confidence supplier';
    case SupplierTrustBand.stable:
      return 'Reliable supplier';
    case SupplierTrustBand.watchlist:
      return 'Needs closer review';
  }
}

List<SupplierTrustMetric> supplierTrustMetricsForProfile(
  SupplierTrustProfile profile,
) {
  return <SupplierTrustMetric>[
    SupplierTrustMetric(
      label: 'Fulfillment success',
      value: formatTrustPercent(profile.fulfillmentSuccessRate),
      hint: 'Delivered cleanly',
    ),
    SupplierTrustMetric(
      label: 'Average delivery',
      value: formatTrustDays(profile.averageDeliveryDays),
      hint: 'Days to buyer',
    ),
    SupplierTrustMetric(
      label: 'Return rate',
      value: formatTrustPercent(profile.returnRate),
      hint: 'Lower is better',
    ),
    SupplierTrustMetric(
      label: 'Orders last 30d',
      value: formatTrustCount(profile.shippedOrders30d),
      hint: 'Shipped orders',
    ),
    SupplierTrustMetric(
      label: 'Min issue rate',
      value: formatTrustPercent(profile.minimumIssueRate),
      hint: 'Quality floor',
    ),
  ];
}

String formatTrustPercent(double? value) {
  if (value == null) return '--';
  final rounded = value.clamp(0, 100).toStringAsFixed(0);
  return '$rounded%';
}

String formatTrustDays(double? value) {
  if (value == null) return '--';
  final rounded = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return '$rounded d';
}

String formatTrustCount(int? value) {
  if (value == null) return '--';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return value.toString();
}
