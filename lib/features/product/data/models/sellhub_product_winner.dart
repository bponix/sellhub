class SellHubProductWinner {
  const SellHubProductWinner({
    required this.productId,
    required this.title,
    required this.slug,
    required this.thumbnail,
    required this.score,
    required this.tier,
    required this.badges,
    required this.reasons,
    required this.nextAction,
    required this.orderCount,
    required this.quoteCount,
    required this.reorderCount,
    required this.attributedOrderCount,
    required this.profitMarginPct,
    required this.localDemandScore,
    required this.supplierQualityScore,
    required this.supplierQualityTier,
    required this.payoutProofScore,
    required this.payoutProofTier,
  });

  final int productId;
  final String title;
  final String slug;
  final String thumbnail;
  final int score;
  final String tier;
  final List<String> badges;
  final List<String> reasons;
  final String nextAction;
  final int orderCount;
  final int quoteCount;
  final int reorderCount;
  final int attributedOrderCount;
  final double profitMarginPct;
  final int localDemandScore;
  final int supplierQualityScore;
  final String supplierQualityTier;
  final int payoutProofScore;
  final String payoutProofTier;

  factory SellHubProductWinner.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) => value is List
        ? value.whereType<String>().toList(growable: false)
        : const <String>[];

    return SellHubProductWinner(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled product',
      slug: json['slug'] as String? ?? 'product',
      thumbnail: json['thumbnail'] as String? ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      tier: json['tier'] as String? ?? 'emerging',
      badges: strings(json['badges']),
      reasons: strings(json['reasons']),
      nextAction: json['nextAction'] as String? ?? 'review-product',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      quoteCount: (json['quoteCount'] as num?)?.toInt() ?? 0,
      reorderCount: (json['reorderCount'] as num?)?.toInt() ?? 0,
      attributedOrderCount:
          (json['attributedOrderCount'] as num?)?.toInt() ?? 0,
      profitMarginPct: (json['profitMarginPct'] as num?)?.toDouble() ?? 0,
      localDemandScore: (json['localDemandScore'] as num?)?.toInt() ?? 0,
      supplierQualityScore:
          (json['supplierQualityScore'] as num?)?.toInt() ?? 0,
      supplierQualityTier: json['supplierQualityTier'] as String? ?? 'unproven',
      payoutProofScore: (json['payoutProofScore'] as num?)?.toInt() ?? 0,
      payoutProofTier: json['payoutProofTier'] as String? ?? 'unproven',
    );
  }
}
