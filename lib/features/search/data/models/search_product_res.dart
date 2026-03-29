class SearchProductRes {
  final int id;
  final String title;
  final String thumbnail;
  final double price;
  final double comparePrice;
  final int siteId;
  final String sku;

  SearchProductRes({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.comparePrice,
    required this.siteId,
    required this.sku,
  });

  factory SearchProductRes.fromJson(Map<String, dynamic> json) {
    return SearchProductRes(
      id: json['id'],
      title: json['title'],
      thumbnail: json['thumbnail'],
      price: (json['price'] as num).toDouble(),
      comparePrice: (json['compare_price'] as num).toDouble(),
      siteId: json['site_id'],
      sku: json['sku'],
    );
  }
}
