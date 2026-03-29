class OrderHistoryResModelProfile {
  OrderHistoryResModelProfile({
    required this.createdAt,
    required this.currency,
    required this.customerAddress,
    required this.customerName,
    required this.customerNote,
    required this.customerPhone,
    required this.id,
    required this.isSettle,
    required this.orderId,
    required this.paid,
    required this.profit,
    required this.resellAmount,
    required this.status,
    required this.total,
    required this.updatedAt,
  });

  final DateTime? createdAt;
  final String? currency;
  final String? customerAddress;
  final String? customerName;
  final String? customerNote;
  final int? customerPhone;
  final int? id;
  final bool? isSettle;
  final String? orderId;
  final double? paid;
  final double? profit;
  final double? resellAmount;
  final int? status;
  final double? total;
  final DateTime? updatedAt;

  factory OrderHistoryResModelProfile.fromJson(Map<String, dynamic> json) {
    return OrderHistoryResModelProfile(
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      currency: json["currency"],
      customerAddress: json["customerAddress"],
      customerName: json["customerName"],
      customerNote: json["customerNote"],
      customerPhone: json["customerPhone"],
      id: json["id"],
      isSettle: json["isSettle"],
      orderId: json["orderId"],
      paid: json["paid"],
      profit: json["profit"],
      resellAmount: json["resellAmount"],
      status: json["status"],
      total: json["total"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }
}
