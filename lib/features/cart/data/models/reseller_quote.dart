class ResellerQuote {
  const ResellerQuote({
    required this.id,
    required this.siteId,
    required this.userId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.deliveryLabel,
    required this.deliveryEstimate,
    required this.deliveryCharge,
    required this.subtotal,
    required this.total,
    required this.baseTotal,
    required this.profit,
    required this.createdAt,
    required this.status,
    required this.lines,
    this.orderId,
  });

  final String id;
  final int siteId;
  final int userId;
  final String buyerName;
  final int buyerPhone;
  final String buyerAddress;
  final String deliveryLabel;
  final String deliveryEstimate;
  final int deliveryCharge;
  final int subtotal;
  final int total;
  final int baseTotal;
  final int profit;
  final DateTime createdAt;
  final String status;
  final String? orderId;
  final List<ResellerQuoteLine> lines;

  factory ResellerQuote.fromJson(Map<String, dynamic> json) {
    return ResellerQuote(
      id: (json['id'] as String?) ?? '',
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      buyerName: (json['buyerName'] as String?) ?? '',
      buyerPhone: (json['buyerPhone'] as num?)?.toInt() ?? 0,
      buyerAddress: (json['buyerAddress'] as String?) ?? '',
      deliveryLabel: (json['deliveryLabel'] as String?) ?? '',
      deliveryEstimate: (json['deliveryEstimate'] as String?) ?? '',
      deliveryCharge: (json['deliveryCharge'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      baseTotal: (json['baseTotal'] as num?)?.toInt() ?? 0,
      profit: (json['profit'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      status: (json['status'] as String?) ?? 'draft',
      orderId: json['orderId'] as String?,
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => ResellerQuoteLine.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'siteId': siteId,
      'userId': userId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'deliveryLabel': deliveryLabel,
      'deliveryEstimate': deliveryEstimate,
      'deliveryCharge': deliveryCharge,
      'subtotal': subtotal,
      'total': total,
      'baseTotal': baseTotal,
      'profit': profit,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'orderId': orderId,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
    };
  }

  ResellerQuote copyWith({String? status, String? orderId}) {
    return ResellerQuote(
      id: id,
      siteId: siteId,
      userId: userId,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      deliveryLabel: deliveryLabel,
      deliveryEstimate: deliveryEstimate,
      deliveryCharge: deliveryCharge,
      subtotal: subtotal,
      total: total,
      baseTotal: baseTotal,
      profit: profit,
      createdAt: createdAt,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      lines: lines,
    );
  }
}

class ResellerQuoteLine {
  const ResellerQuoteLine({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.quantity,
    required this.basePrice,
    required this.sellPrice,
  });

  final int? productId;
  final String title;
  final String thumbnail;
  final int quantity;
  final int basePrice;
  final int sellPrice;

  int get lineBaseTotal => basePrice * quantity;
  int get lineSellTotal => sellPrice * quantity;

  factory ResellerQuoteLine.fromJson(Map<String, dynamic> json) {
    return ResellerQuoteLine(
      productId: (json['productId'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? '',
      thumbnail: (json['thumbnail'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productId': productId,
      'title': title,
      'thumbnail': thumbnail,
      'quantity': quantity,
      'basePrice': basePrice,
      'sellPrice': sellPrice,
    };
  }
}
