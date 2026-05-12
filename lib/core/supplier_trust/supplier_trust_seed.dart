import 'package:sellhub/core/supplier_trust/supplier_trust_model.dart';

class SupplierTrustSeedInput {
  const SupplierTrustSeedInput({
    required this.siteId,
    required this.domain,
    required this.title,
  });

  final int siteId;
  final String domain;
  final String title;
}

class SupplierTrustSeedFactory {
  SupplierTrustSeedFactory._();

  static const List<String> _categoryPool = <String>[
    'Fashion',
    'Beauty',
    'Home',
    'Kitchen',
    'Electronics',
    'Baby Care',
    'Health',
    'Lifestyle',
  ];

  static SupplierTrustProfile build(SupplierTrustSeedInput input) {
    final normalizedDomain = input.domain.trim().toLowerCase();
    final normalizedTitle = input.title.trim().toLowerCase();
    final hash = _hash('${input.siteId}|$normalizedDomain|$normalizedTitle');

    final score = 58 + (hash % 38);
    final fulfillment = 85 + ((hash >> 3) % 14);
    final averageDeliveryDays =
        1.2 + (((hash >> 5) % 22) / 10.0);
    final returnRate = 1 + ((hash >> 7) % 8);
    final shippedOrders30d = 36 + ((hash >> 9) % 540);
    final minimumIssueRate = 1 + ((hash >> 11) % 5);
    final paysResellersOnTime = score >= 74 || (hash % 5 != 0);
    final verified = score >= 60;
    final categoryCount = 2 + (hash % 2);
    final topCategories = <String>[];

    for (var i = 0; i < categoryCount; i++) {
      final index = ((hash >> (i * 3)) + i) % _categoryPool.length;
      final category = _categoryPool[index];
      if (!topCategories.contains(category)) {
        topCategories.add(category);
      }
    }

    final note = score >= 80
        ? 'Strong supplier trust with steady reseller-safe fulfillment.'
        : score >= 68
        ? 'Stable supplier performance for repeat selling.'
        : 'Watch this supplier more closely before scaling volume.';

    return SupplierTrustProfile(
      score: score.toDouble(),
      verified: verified,
      fulfillmentSuccessRate: fulfillment.toDouble(),
      averageDeliveryDays: averageDeliveryDays,
      returnRate: returnRate.toDouble(),
      shippedOrders30d: shippedOrders30d,
      paysResellersOnTime: paysResellersOnTime,
      topCategories: topCategories,
      minimumIssueRate: minimumIssueRate.toDouble(),
      note: note,
      supplierName: input.title.trim().isEmpty ? input.domain : input.title,
    );
  }

  static int _hash(String value) {
    var hash = 2166136261;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash.abs();
  }
}
