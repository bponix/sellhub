import 'package:flutter/material.dart';
import 'package:sellhub/core/constants/app_color.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_seed.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust_seed.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

enum ViabilityRiskLevel { low, moderate, high }

class ProductViabilityProfile {
  const ProductViabilityProfile({
    required this.supplierName,
    required this.baseCost,
    required this.minSellPrice,
    required this.maxSellPrice,
    required this.minMargin,
    required this.maxMargin,
    required this.demandScore,
    required this.shareabilityScore,
    required this.trustScore,
    required this.deliveryRisk,
    required this.returnSensitivity,
    required this.labels,
    required this.reasons,
  });

  final String supplierName;
  final double baseCost;
  final double minSellPrice;
  final double maxSellPrice;
  final double minMargin;
  final double maxMargin;
  final double demandScore;
  final double shareabilityScore;
  final double trustScore;
  final ViabilityRiskLevel deliveryRisk;
  final ViabilityRiskLevel returnSensitivity;
  final List<String> labels;
  final List<String> reasons;

  String get demandLabel => _scoreLabel(demandScore);
  String get shareabilityLabel => _scoreLabel(shareabilityScore);

  static String _scoreLabel(double score) {
    if (score >= 80) return 'High';
    if (score >= 60) return 'Medium';
    return 'Low';
  }
}

class ProductViabilityEngine {
  ProductViabilityEngine._();

  static ProductViabilityProfile build(ProductResCommon product) {
    final supplier = SellHubCatalogSeed.suppliers.firstWhere(
      (item) => (item['id'] as num?)?.toInt() == product.siteId,
      orElse: () => <String, dynamic>{
        'id': product.siteId ?? 0,
        'domain': '',
        'title': '',
      },
    );
    final trust = SupplierTrustSeedFactory.build(
      SupplierTrustSeedInput(
        siteId: product.siteId ?? 0,
        domain: (supplier['domain'] as String?) ?? '',
        title: (supplier['title'] as String?) ?? '',
      ),
    );

    final baseCost = product.wholesalePrice ?? product.price ?? 0;
    final minSell = product.minResellPrice ?? product.price ?? 0;
    final maxSell =
        product.maxResellPrice ?? product.comparePrice ?? product.price ?? 0;
    final minMargin =
        (minSell - baseCost).clamp(0, double.infinity).toDouble();
    final maxMargin =
        (maxSell - baseCost).clamp(0, double.infinity).toDouble();
    final marginPct = baseCost <= 0 ? 0 : (minMargin / baseCost) * 100;
    final rating = (product.rating ?? 0).clamp(0, 5);
    final ratingTotal = (product.ratingTotal ?? 0).clamp(0, 9999);
    final isFlash = product.isFlash == true;
    final isBeautyLike = _matches(product, const ['beauty', 'skin', 'serum']);
    final isHomeLike = _matches(product, const ['home', 'kitchen', 'storage']);
    final isFashionLike = _matches(product, const ['fashion', 'shirt', 'bag']);

    final demandScore = (
      28 +
      (rating * 11) +
      (ratingTotal >= 80 ? 18 : ratingTotal >= 30 ? 10 : 4) +
      (isFlash ? 12 : 0) +
      (trust.score * 0.22)
    ).clamp(0, 100).toDouble();

    final shareabilityScore = (
      22 +
      (marginPct.clamp(0, 35) * 1.1) +
      (isFashionLike ? 12 : 0) +
      (isBeautyLike ? 10 : 0) +
      ((product.comparePrice ?? 0) > (product.price ?? 0) ? 8 : 0) +
      (trust.score * 0.18)
    ).clamp(0, 100).toDouble();

    final deliveryRiskValue = (
      (trust.averageDeliveryDays ?? 3.5) * 14 +
      ((product.weight ?? 0.3) * 18) +
      (trust.score < 55 ? 18 : 0)
    ).clamp(0, 100).toDouble();
    final deliveryRisk = _riskLevel(
      deliveryRiskValue,
      reverse: true,
      lowCutoff: 36,
      highCutoff: 62,
    );

    final returnSensitivityValue = (
      (trust.returnRate ?? 6) * 8 +
      (isFashionLike ? 16 : 0) +
      (isBeautyLike ? 10 : 0)
    ).clamp(0, 100).toDouble();
    final returnSensitivity = _riskLevel(
      returnSensitivityValue,
      reverse: true,
      lowCutoff: 28,
      highCutoff: 52,
    );

    final labels = <String>[
      if (demandScore >= 78 || isFlash) 'Fast mover',
      if (marginPct >= 18 || minMargin >= 150) 'Good margin',
      if (trust.score >= 72 &&
          deliveryRisk != ViabilityRiskLevel.high &&
          minMargin >= 80) 'Beginner friendly',
      if (isBeautyLike || isHomeLike) 'High repeat potential',
      if (deliveryRisk == ViabilityRiskLevel.high) 'Risky delivery zone',
      if (trust.score < 55) 'Low trust supplier',
    ];

    final reasons = <String>[
      'Base cost is ৳${baseCost.round()} with a sell window of ৳${minSell.round()} to ৳${maxSell.round()}.',
      'Expected reseller margin ranges from ৳${minMargin.round()} to ৳${maxMargin.round()}.',
      'Demand signal is ${demandScore.round()}/100 based on ratings, popularity, flash momentum, and supplier quality.',
      'Shareability score is ${shareabilityScore.round()}/100 based on margin room, visual category fit, and offer attractiveness.',
      'Supplier trust score is ${trust.score.round()}/100 from fulfillment success, returns, delivery speed, and payout consistency.',
      'Delivery risk is ${viabilityRiskLabel(deliveryRisk).toLowerCase()} and return sensitivity is ${viabilityRiskLabel(returnSensitivity).toLowerCase()}.',
    ];

    return ProductViabilityProfile(
      supplierName: ((supplier['title'] as String?)?.trim().isNotEmpty ?? false)
          ? (supplier['title'] as String).trim()
          : 'Supplier',
      baseCost: baseCost,
      minSellPrice: minSell,
      maxSellPrice: maxSell,
      minMargin: minMargin,
      maxMargin: maxMargin,
      demandScore: demandScore,
      shareabilityScore: shareabilityScore,
      trustScore: trust.score,
      deliveryRisk: deliveryRisk,
      returnSensitivity: returnSensitivity,
      labels: labels,
      reasons: reasons,
    );
  }

  static bool _matches(ProductResCommon product, List<String> terms) {
    final haystack = <String>[
      product.title ?? '',
      product.translation ?? '',
      ...product.brands,
      ...product.features.map((item) => '${item.key} ${item.value}'),
    ].join(' ').toLowerCase();
    return terms.any(haystack.contains);
  }

  static ViabilityRiskLevel _riskLevel(
    double value, {
    required bool reverse,
    required double lowCutoff,
    required double highCutoff,
  }) {
    if (!reverse) {
      if (value >= highCutoff) return ViabilityRiskLevel.high;
      if (value >= lowCutoff) return ViabilityRiskLevel.moderate;
      return ViabilityRiskLevel.low;
    }
    if (value >= highCutoff) return ViabilityRiskLevel.high;
    if (value >= lowCutoff) return ViabilityRiskLevel.moderate;
    return ViabilityRiskLevel.low;
  }
}

enum ProductViabilityFilter {
  all,
  fastMover,
  goodMargin,
  beginnerFriendly,
  highRepeatPotential,
  riskyDeliveryZone,
  lowTrustSupplier,
}

enum ProductViabilitySort {
  featured,
  strongestDemand,
  highestMargin,
  lowestRisk,
  beginnerFriendly,
  highRepeatPotential,
}

List<ProductResCommon> applyProductViability(
  List<ProductResCommon> products, {
  ProductViabilityFilter filter = ProductViabilityFilter.all,
  ProductViabilitySort sort = ProductViabilitySort.featured,
}) {
  final filtered = products.where((product) {
    final profile = ProductViabilityEngine.build(product);
    switch (filter) {
      case ProductViabilityFilter.all:
        return true;
      case ProductViabilityFilter.fastMover:
        return profile.labels.contains('Fast mover');
      case ProductViabilityFilter.goodMargin:
        return profile.labels.contains('Good margin');
      case ProductViabilityFilter.beginnerFriendly:
        return profile.labels.contains('Beginner friendly');
      case ProductViabilityFilter.highRepeatPotential:
        return profile.labels.contains('High repeat potential');
      case ProductViabilityFilter.riskyDeliveryZone:
        return profile.labels.contains('Risky delivery zone');
      case ProductViabilityFilter.lowTrustSupplier:
        return profile.labels.contains('Low trust supplier');
    }
  }).toList(growable: false);

  final sorted = List<ProductResCommon>.from(filtered);
  sorted.sort((a, b) {
    final aProfile = ProductViabilityEngine.build(a);
    final bProfile = ProductViabilityEngine.build(b);
    switch (sort) {
      case ProductViabilitySort.featured:
        return _featuredScore(bProfile).compareTo(_featuredScore(aProfile));
      case ProductViabilitySort.strongestDemand:
        return bProfile.demandScore.compareTo(aProfile.demandScore);
      case ProductViabilitySort.highestMargin:
        return bProfile.maxMargin.compareTo(aProfile.maxMargin);
      case ProductViabilitySort.lowestRisk:
        return _riskScore(aProfile).compareTo(_riskScore(bProfile));
      case ProductViabilitySort.beginnerFriendly:
        return _beginnerScore(bProfile).compareTo(_beginnerScore(aProfile));
      case ProductViabilitySort.highRepeatPotential:
        return _repeatScore(bProfile).compareTo(_repeatScore(aProfile));
    }
  });
  return sorted;
}

double _featuredScore(ProductViabilityProfile profile) {
  return profile.demandScore * 0.35 +
      profile.shareabilityScore * 0.2 +
      profile.trustScore * 0.2 +
      profile.maxMargin * 0.1 -
      _riskScore(profile) * 4;
}

double _riskScore(ProductViabilityProfile profile) {
  return _riskValue(profile.deliveryRisk) + _riskValue(profile.returnSensitivity);
}

double _beginnerScore(ProductViabilityProfile profile) {
  return (profile.labels.contains('Beginner friendly') ? 100 : 0) +
      profile.trustScore -
      _riskScore(profile) * 12 +
      profile.minMargin * 0.05;
}

double _repeatScore(ProductViabilityProfile profile) {
  return (profile.labels.contains('High repeat potential') ? 100 : 0) +
      profile.demandScore +
      profile.trustScore * 0.4;
}

double _riskValue(ViabilityRiskLevel risk) {
  switch (risk) {
    case ViabilityRiskLevel.low:
      return 1;
    case ViabilityRiskLevel.moderate:
      return 2;
    case ViabilityRiskLevel.high:
      return 3;
  }
}

Color viabilityRiskColor(ViabilityRiskLevel risk) {
  switch (risk) {
    case ViabilityRiskLevel.low:
      return AppColor.green;
    case ViabilityRiskLevel.moderate:
      return AppColor.warning;
    case ViabilityRiskLevel.high:
      return AppColor.alert;
  }
}

Color viabilityRiskSoftColor(ViabilityRiskLevel risk) {
  switch (risk) {
    case ViabilityRiskLevel.low:
      return const Color(0xFFEAF8F1);
    case ViabilityRiskLevel.moderate:
      return AppColor.warningLight;
    case ViabilityRiskLevel.high:
      return AppColor.alertLight;
  }
}

String viabilityRiskLabel(ViabilityRiskLevel risk) {
  switch (risk) {
    case ViabilityRiskLevel.low:
      return 'Low';
    case ViabilityRiskLevel.moderate:
      return 'Medium';
    case ViabilityRiskLevel.high:
      return 'High';
  }
}
