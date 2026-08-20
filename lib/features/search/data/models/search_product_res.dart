class SearchProductRes {
  final int id;
  final String title;
  final String thumbnail;
  final double price;
  final double comparePrice;
  final double wholesalePrice;
  final double minResellPrice;
  final double maxResellPrice;
  final int siteId;
  final String sku;

  SearchProductRes({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.comparePrice,
    required this.wholesalePrice,
    required this.minResellPrice,
    required this.maxResellPrice,
    required this.siteId,
    required this.sku,
  });

  factory SearchProductRes.fromJson(Map<String, dynamic> json) {
    return SearchProductRes(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: '${json['title'] ?? ''}',
      thumbnail: '${json['thumbnail'] ?? ''}',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice:
          (json['comparePrice'] ?? json['compare_price'] ?? json['price'] ?? 0)
              .toDouble(),
      wholesalePrice:
          ((json['wholesalePrice'] ??
                      json['wholesale_price'] ??
                      json['price'] ??
                      0)
                  as num)
              .toDouble(),
      minResellPrice:
          ((json['minResellPrice'] ??
                      json['min_resell_price'] ??
                      json['price'] ??
                      0)
                  as num)
              .toDouble(),
      maxResellPrice:
          ((json['maxResellPrice'] ??
                      json['max_resell_price'] ??
                      json['comparePrice'] ??
                      json['compare_price'] ??
                      json['price'] ??
                      0)
                  as num)
              .toDouble(),
      siteId: ((json['siteId'] ?? json['site_id']) as num?)?.toInt() ?? 0,
      sku: '${json['sku'] ?? ''}',
    );
  }
}
