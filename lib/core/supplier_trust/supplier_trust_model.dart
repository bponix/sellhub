enum SupplierTrustBand { strong, stable, watchlist }

class SupplierTrustProfile {
  const SupplierTrustProfile({
    required this.score,
    this.verified = false,
    this.updatedAt,
    this.fulfillmentSuccessRate,
    this.averageDeliveryDays,
    this.returnRate,
    this.shippedOrders30d,
    this.paysResellersOnTime,
    this.topCategories = const <String>[],
    this.minimumIssueRate,
    this.note,
    this.supplierName,
  });

  final double score;
  final bool verified;
  final DateTime? updatedAt;
  final double? fulfillmentSuccessRate;
  final double? averageDeliveryDays;
  final double? returnRate;
  final int? shippedOrders30d;
  final bool? paysResellersOnTime;
  final List<String> topCategories;
  final double? minimumIssueRate;
  final String? note;
  final String? supplierName;

  factory SupplierTrustProfile.fromJson(Map<String, dynamic> json) {
    return SupplierTrustProfile(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      verified: json['isVerified'] as bool? ?? false,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
      fulfillmentSuccessRate:
          (json['fulfillmentSuccessRate'] as num?)?.toDouble(),
      averageDeliveryDays: (json['averageDeliveryDays'] as num?)?.toDouble(),
      returnRate: (json['returnRate'] as num?)?.toDouble(),
      shippedOrders30d: json['shippedOrders30d'] as int?,
      paysResellersOnTime: json['paysResellersOnTime'] as bool?,
      topCategories: (json['topCategories'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      minimumIssueRate: (json['minimumIssueRate'] as num?)?.toDouble(),
      note: json['note'] as String?,
      supplierName: json['supplierName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'score': score,
    'isVerified': verified,
    'updatedAt': updatedAt?.toIso8601String(),
    'fulfillmentSuccessRate': fulfillmentSuccessRate,
    'averageDeliveryDays': averageDeliveryDays,
    'returnRate': returnRate,
    'shippedOrders30d': shippedOrders30d,
    'paysResellersOnTime': paysResellersOnTime,
    'topCategories': topCategories,
    'minimumIssueRate': minimumIssueRate,
    'note': note,
    'supplierName': supplierName,
  };

  SupplierTrustProfile copyWith({
    double? score,
    bool? verified,
    DateTime? updatedAt,
    double? fulfillmentSuccessRate,
    double? averageDeliveryDays,
    double? returnRate,
    int? shippedOrders30d,
    bool? paysResellersOnTime,
    List<String>? topCategories,
    double? minimumIssueRate,
    String? note,
    String? supplierName,
  }) {
    return SupplierTrustProfile(
      score: score ?? this.score,
      verified: verified ?? this.verified,
      updatedAt: updatedAt ?? this.updatedAt,
      fulfillmentSuccessRate:
          fulfillmentSuccessRate ?? this.fulfillmentSuccessRate,
      averageDeliveryDays: averageDeliveryDays ?? this.averageDeliveryDays,
      returnRate: returnRate ?? this.returnRate,
      shippedOrders30d: shippedOrders30d ?? this.shippedOrders30d,
      paysResellersOnTime: paysResellersOnTime ?? this.paysResellersOnTime,
      topCategories: topCategories ?? this.topCategories,
      minimumIssueRate: minimumIssueRate ?? this.minimumIssueRate,
      note: note ?? this.note,
      supplierName: supplierName ?? this.supplierName,
    );
  }
}

class SupplierTrustMetric {
  const SupplierTrustMetric({
    required this.label,
    required this.value,
    this.hint,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final List<List<dynamic>>? icon;

  SupplierTrustMetric copyWith({
    String? label,
    String? value,
    String? hint,
    List<List<dynamic>>? icon,
  }) {
    return SupplierTrustMetric(
      label: label ?? this.label,
      value: value ?? this.value,
      hint: hint ?? this.hint,
      icon: icon ?? this.icon,
    );
  }
}
