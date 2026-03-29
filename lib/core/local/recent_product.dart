class RecentProduct {
  const RecentProduct({
    required this.hid,
    required this.siteId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.comparePrice,
    required this.brand,
  });

  final String hid;
  final int siteId;
  final String title;
  final String thumbnail;
  final double price;
  final double comparePrice;
  final String brand;

  factory RecentProduct.fromJson(Map<String, dynamic> json) {
    return RecentProduct(
      hid: (json['hid'] as String? ?? '').trim(),
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String? ?? '').trim(),
      thumbnail: (json['thumbnail'] as String? ?? '').trim(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice: (json['comparePrice'] as num?)?.toDouble() ?? 0,
      brand: (json['brand'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hid': hid,
    'siteId': siteId,
    'title': title,
    'thumbnail': thumbnail,
    'price': price,
    'comparePrice': comparePrice,
    'brand': brand,
  };
}
