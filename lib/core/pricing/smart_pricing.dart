import 'dart:math' as math;

enum SmartPricingWarningLevel { good, notice, warning, risk }

enum SmartPricingChannelPreset {
  whatsappQuickSell,
  facebookPost,
  codFirst,
  premiumBuyer,
}

class ProductPricingMemory {
  const ProductPricingMemory({
    required this.productId,
    required this.siteId,
    required this.userId,
    required this.lastSuccessfulPrice,
    required this.mostCommonSuccessfulPrice,
    required this.successfulOrderCount,
    required this.priceFrequency,
  });

  final int productId;
  final int siteId;
  final int userId;
  final int? lastSuccessfulPrice;
  final int? mostCommonSuccessfulPrice;
  final int successfulOrderCount;
  final Map<int, int> priceFrequency;

  factory ProductPricingMemory.fromJson(Map<String, dynamic> json) {
    final rawFrequency =
        (json['priceFrequency'] as Map?)?.map(
          (key, value) => MapEntry(
            int.tryParse(key.toString()) ?? 0,
            (value as num?)?.toInt() ?? 0,
          ),
        ) ??
        const <int, int>{};
    return ProductPricingMemory(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      lastSuccessfulPrice: (json['lastSuccessfulPrice'] as num?)?.toInt(),
      mostCommonSuccessfulPrice: (json['mostCommonSuccessfulPrice'] as num?)
          ?.toInt(),
      successfulOrderCount:
          (json['successfulOrderCount'] as num?)?.toInt() ?? 0,
      priceFrequency: rawFrequency,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productId': productId,
      'siteId': siteId,
      'userId': userId,
      'lastSuccessfulPrice': lastSuccessfulPrice,
      'mostCommonSuccessfulPrice': mostCommonSuccessfulPrice,
      'successfulOrderCount': successfulOrderCount,
      'priceFrequency': priceFrequency.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}

class SmartPriceOption {
  const SmartPriceOption({
    required this.label,
    required this.price,
    required this.marginPerItem,
    required this.description,
  });

  final String label;
  final int price;
  final int marginPerItem;
  final String description;
}

class SmartPricingWarning {
  const SmartPricingWarning({
    required this.level,
    required this.title,
    required this.message,
  });

  final SmartPricingWarningLevel level;
  final String title;
  final String message;
}

class SmartPricingProfile {
  const SmartPricingProfile({
    required this.minimumSafePrice,
    required this.recommendedPrice,
    required this.premiumPrice,
    required this.realisticMinPrice,
    required this.realisticMaxPrice,
    required this.minimumSafeMargin,
    required this.recommendedMargin,
    required this.premiumMargin,
    required this.options,
    required this.channelPresets,
    required this.memory,
  });

  final int minimumSafePrice;
  final int recommendedPrice;
  final int premiumPrice;
  final int realisticMinPrice;
  final int realisticMaxPrice;
  final int minimumSafeMargin;
  final int recommendedMargin;
  final int premiumMargin;
  final List<SmartPriceOption> options;
  final Map<SmartPricingChannelPreset, SmartPriceOption> channelPresets;
  final ProductPricingMemory? memory;

  SmartPricingWarning warningForPrice(int price) {
    if (price < minimumSafePrice) {
      return const SmartPricingWarning(
        level: SmartPricingWarningLevel.risk,
        title: 'Too low for safe margin',
        message:
            'This price leaves very little room for reseller profit after delivery issues, returns, or discounts.',
      );
    }
    if (price < realisticMinPrice) {
      return const SmartPricingWarning(
        level: SmartPricingWarningLevel.warning,
        title: 'Below realistic conversion band',
        message:
            'You can place the order, but this price is weaker than the most reliable selling zone.',
      );
    }
    if (price > realisticMaxPrice) {
      return const SmartPricingWarning(
        level: SmartPricingWarningLevel.notice,
        title: 'Above realistic conversion band',
        message:
            'This premium price is valid, but conversion can slow down unless the buyer is already warm.',
      );
    }
    return const SmartPricingWarning(
      level: SmartPricingWarningLevel.good,
      title: 'Healthy sell price',
      message: 'This price sits inside the strongest conversion band.',
    );
  }
}

class SmartPricingEngine {
  const SmartPricingEngine._();

  static SmartPricingProfile build({
    required int basePrice,
    required int minSellPrice,
    required int maxSellPrice,
    ProductPricingMemory? memory,
  }) {
    final resolvedBase = math.max(basePrice, 1);
    final resolvedMin = math.max(minSellPrice, resolvedBase);
    final resolvedMax = math.max(maxSellPrice, resolvedMin);
    final spread = math.max(resolvedMax - resolvedMin, 0);
    final safeBuffer = math.max(
      40,
      math.max((resolvedBase * 0.08).round(), (spread * 0.10).round()),
    );
    final minimumSafePrice = _clamp(
      math.max(resolvedMin, resolvedBase + safeBuffer),
      resolvedMin,
      resolvedMax,
    );

    final memoryAnchor = _bestMemoryAnchor(memory);
    final defaultRecommended = _clamp(
      minimumSafePrice + math.max(40, (spread * 0.42).round()),
      minimumSafePrice,
      resolvedMax,
    );
    final recommendedPrice = _clamp(
      memoryAnchor == null
          ? defaultRecommended
          : ((defaultRecommended * 0.58) + (memoryAnchor * 0.42)).round(),
      minimumSafePrice,
      resolvedMax,
    );
    final premiumPrice = _clamp(
      math.max(
        recommendedPrice + math.max(45, (spread * 0.18).round()),
        memory?.lastSuccessfulPrice ?? 0,
      ),
      recommendedPrice,
      resolvedMax,
    );

    final realisticMinPrice = _clamp(
      math.max(
        minimumSafePrice,
        recommendedPrice - math.max(30, (spread * 0.14).round()),
      ),
      minimumSafePrice,
      resolvedMax,
    );
    final realisticMaxPrice = _clamp(
      math.min(
        resolvedMax,
        recommendedPrice + math.max(35, (spread * 0.16).round()),
      ),
      realisticMinPrice,
      resolvedMax,
    );

    final options = <SmartPriceOption>[
      SmartPriceOption(
        label: 'Minimum safe',
        price: minimumSafePrice,
        marginPerItem: minimumSafePrice - resolvedBase,
        description: 'Protects minimum healthy reseller margin.',
      ),
      SmartPriceOption(
        label: 'Recommended',
        price: recommendedPrice,
        marginPerItem: recommendedPrice - resolvedBase,
        description: 'Best balance between conversion and margin.',
      ),
      SmartPriceOption(
        label: 'Premium',
        price: premiumPrice,
        marginPerItem: premiumPrice - resolvedBase,
        description: 'Best for warm buyers who trust the offer already.',
      ),
    ];

    final channelPresets =
        <SmartPricingChannelPreset, SmartPriceOption>{
          SmartPricingChannelPreset.whatsappQuickSell: SmartPriceOption(
            label: 'WhatsApp quick sell',
            price: _clamp(
              math.max(
                minimumSafePrice,
                recommendedPrice - math.max(20, (spread * 0.10).round()),
              ),
              minimumSafePrice,
              resolvedMax,
            ),
            marginPerItem: 0,
            description: 'Faster close for direct chat buyers.',
          ),
          SmartPricingChannelPreset.facebookPost: SmartPriceOption(
            label: 'Facebook post',
            price: _clamp(
              memory?.mostCommonSuccessfulPrice ?? recommendedPrice,
              minimumSafePrice,
              resolvedMax,
            ),
            marginPerItem: 0,
            description: 'Balanced public-post pricing with broad appeal.',
          ),
          SmartPricingChannelPreset.codFirst: SmartPriceOption(
            label: 'COD-first',
            price: _clamp(
              math.max(
                minimumSafePrice,
                recommendedPrice - math.max(15, (spread * 0.08).round()),
              ),
              minimumSafePrice,
              resolvedMax,
            ),
            marginPerItem: 0,
            description:
                'Safer for cash-on-delivery buyers who hesitate on price.',
          ),
          SmartPricingChannelPreset.premiumBuyer: SmartPriceOption(
            label: 'Premium buyer',
            price: premiumPrice,
            marginPerItem: 0,
            description:
                'Higher confidence pricing for repeat or urgent buyers.',
          ),
        }.map(
          (key, value) => MapEntry(
            key,
            SmartPriceOption(
              label: value.label,
              price: value.price,
              marginPerItem: value.price - resolvedBase,
              description: value.description,
            ),
          ),
        );

    return SmartPricingProfile(
      minimumSafePrice: minimumSafePrice,
      recommendedPrice: recommendedPrice,
      premiumPrice: premiumPrice,
      realisticMinPrice: realisticMinPrice,
      realisticMaxPrice: realisticMaxPrice,
      minimumSafeMargin: minimumSafePrice - resolvedBase,
      recommendedMargin: recommendedPrice - resolvedBase,
      premiumMargin: premiumPrice - resolvedBase,
      options: options,
      channelPresets: channelPresets,
      memory: memory,
    );
  }

  static int _clamp(int value, int min, int max) {
    return value.clamp(min, max);
  }

  static int? _bestMemoryAnchor(ProductPricingMemory? memory) {
    final mostCommon = memory?.mostCommonSuccessfulPrice;
    if (mostCommon != null && mostCommon > 0) return mostCommon;
    final last = memory?.lastSuccessfulPrice;
    if (last != null && last > 0) return last;
    return null;
  }
}
