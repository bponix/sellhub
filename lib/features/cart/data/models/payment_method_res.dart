class PaymentMethodRes {
  PaymentMethodRes({
    required this.discount,
    required this.fee,
    required this.gatewayType,
    required this.id,
    required this.isActive,
    required this.isDiscount,
    required this.isFreeLogistics,
    required this.isManual,
    required this.isSandbox,
    required this.note,
    required this.priority,
    required this.title,
    required this.logo,
    required this.updatedAt,
  });

  final double? discount;
  final double? fee;
  final int? gatewayType;
  final int? id;
  final bool? isActive;
  final bool? isDiscount;
  final bool? isFreeLogistics;
  final bool? isManual;
  final bool? isSandbox;
  final String? note;
  final int? priority;
  final String? title;
  final String? logo;
  final DateTime? updatedAt;

  factory PaymentMethodRes.fromJson(Map<String, dynamic> json) {
    return PaymentMethodRes(
      discount: json["discount"],
      fee: json["fee"],
      gatewayType: json["gatewayType"],
      id: json["id"],
      isActive: json["isActive"],
      isDiscount: json["isDiscount"],
      isFreeLogistics: json["isFreeLogistics"],
      isManual: json["isManual"],
      isSandbox: json["isSandbox"],
      note: json["note"],
      priority: json["priority"],
      title: json["title"],
      logo: json["logo"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
    "discount": discount,
    "fee": fee,
    "gatewayType": gatewayType,
    "id": id,
    "isActive": isActive,
    "isDiscount": isDiscount,
    "isFreeLogistics": isFreeLogistics,
    "isManual": isManual,
    "isSandbox": isSandbox,
    "note": note,
    "priority": priority,
    "title": title,
    "logo": logo,
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
