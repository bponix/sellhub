class ResellerOrderLineDraft {
  const ResellerOrderLineDraft({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.quantity,
    required this.basePrice,
    required this.sellPrice,
    required this.minSellPrice,
    required this.maxSellPrice,
    required this.vat,
  });

  final int? id;
  final String title;
  final String thumbnail;
  final int quantity;
  final int basePrice;
  final int sellPrice;
  final int minSellPrice;
  final int maxSellPrice;
  final int vat;

  int get lineBaseTotal => basePrice * quantity;
  int get lineSellTotal => sellPrice * quantity;
  int get lineProfit => lineSellTotal - lineBaseTotal;

  factory ResellerOrderLineDraft.fromJson(Map<String, dynamic> json) {
    return ResellerOrderLineDraft(
      id: (json['id'] as num?)?.toInt() ?? (json['productId'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? 'Product',
      thumbnail: (json['thumbnail'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      basePrice:
          (json['basePrice'] as num?)?.toInt() ??
          (json['resellPrice'] as num?)?.toInt() ??
          0,
      sellPrice:
          (json['sellPrice'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      minSellPrice: (json['minSellPrice'] as num?)?.toInt() ?? 0,
      maxSellPrice: (json['maxSellPrice'] as num?)?.toInt() ?? 0,
      vat: (json['vat'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'productId': id,
      'title': title,
      'thumbnail': thumbnail,
      'quantity': quantity,
      'basePrice': basePrice,
      'sellPrice': sellPrice,
      'minSellPrice': minSellPrice,
      'maxSellPrice': maxSellPrice,
      'vat': vat,
    };
  }

  ResellerOrderLineDraft copyWith({
    int? quantity,
    int? sellPrice,
    int? minSellPrice,
    int? maxSellPrice,
  }) {
    return ResellerOrderLineDraft(
      id: id,
      title: title,
      thumbnail: thumbnail,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice,
      sellPrice: sellPrice ?? this.sellPrice,
      minSellPrice: minSellPrice ?? this.minSellPrice,
      maxSellPrice: maxSellPrice ?? this.maxSellPrice,
      vat: vat,
    );
  }
}
