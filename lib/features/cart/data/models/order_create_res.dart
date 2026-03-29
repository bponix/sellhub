class OrderCreateRes {
  OrderCreateRes({
    required this.address,
    required this.affiliateCommission,
    required this.affiliateIsPaid,
    required this.cashbackBalance,
    required this.charge,
    required this.childHid,
    required this.childId,
    required this.cost,
    required this.createdAt,
    required this.currency,
    required this.customerAddress,
    required this.customerId,
    required this.customerName,
    required this.customerNote,
    required this.customerPhone,
    required this.deliveryTime,
    required this.discount,
    required this.discountName,
    required this.emiDuration,
    required this.emiInterest,
    required this.gatewayText,
    required this.grossAmount,
    required this.id,
    required this.image,
    required this.isChargePaid,
    required this.isEmi,
    required this.isPaid,
    required this.isSettle,
    required this.isTransferred,
    required this.latitude,
    required this.logisticsCharge,
    required this.logisticsCityId,
    required this.logisticsExtraCharge,
    required this.logisticsId,
    required this.logisticsIsConfirmed,
    required this.logisticsIsPaid,
    required this.logisticsStoppageId,
    required this.logisticsText,
    required this.logisticsUrl,
    required this.logisticsZoneId,
    required this.longitude,
    required this.netAmount,
    required this.orderId,
    required this.paid,
    required this.paymentId,
    required this.paymentResellerId,
    required this.profit,
    required this.resellAmount,
    required this.resellerAdvanceCollect,
    required this.resellerCommission,
    required this.resellerId,
    required this.resellerIsPaid,
    required this.rewardPoints,
    required this.status,
    required this.statusCompleted,
    required this.total,
    required this.trackingId,
    required this.updatedAt,
    required this.vat,
    required this.vatAmount,
    required this.customer,
    required this.events,
    required this.lines,
  });

  final String? address;
  final int? affiliateCommission;
  final bool? affiliateIsPaid;
  final int? cashbackBalance;
  final int? charge;
  final dynamic childHid;
  final dynamic childId;
  final int? cost;
  final DateTime? createdAt;
  final String? currency;
  final String? customerAddress;
  final int? customerId;
  final String? customerName;
  final String? customerNote;
  final int? customerPhone;
  final dynamic deliveryTime;
  final double? discount;
  final dynamic discountName;
  final int? emiDuration;
  final int? emiInterest;
  final String? gatewayText;
  final int? grossAmount;
  final int? id;
  final dynamic image;
  final bool? isChargePaid;
  final bool? isEmi;
  final bool? isPaid;
  final bool? isSettle;
  final bool? isTransferred;
  final double? latitude;
  final double? logisticsCharge;
  final dynamic logisticsCityId;
  final double? logisticsExtraCharge;
  final int? logisticsId;
  final bool? logisticsIsConfirmed;
  final bool? logisticsIsPaid;
  final dynamic logisticsStoppageId;
  final String? logisticsText;
  final dynamic logisticsUrl;
  final dynamic logisticsZoneId;
  final double? longitude;
  final int? netAmount;
  final String? orderId;
  final int? paid;
  final dynamic paymentId;
  final dynamic paymentResellerId;
  final int? profit;
  final int? resellAmount;
  final int? resellerAdvanceCollect;
  final int? resellerCommission;
  final dynamic resellerId;
  final bool? resellerIsPaid;
  final int? rewardPoints;
  final int? status;
  final List<int> statusCompleted;
  final int? total;
  final dynamic trackingId;
  final DateTime? updatedAt;
  final int? vat;
  final int? vatAmount;
  final dynamic customer;
  final List<Event> events;
  final List<Line> lines;

  factory OrderCreateRes.fromJson(Map<String, dynamic> json) {
    return OrderCreateRes(
      address: json["address"],
      affiliateCommission: _toInt(json["affiliateCommission"]),
      affiliateIsPaid: json["affiliateIsPaid"],
      cashbackBalance: _toInt(json["cashbackBalance"]),
      charge: _toInt(json["charge"]),
      childHid: json["childHid"],
      childId: json["childId"],
      cost: _toInt(json["cost"]),
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      currency: json["currency"],
      customerAddress: json["customerAddress"],
      customerId: _toInt(json["customerId"]),
      customerName: json["customerName"],
      customerNote: json["customerNote"],
      customerPhone: json["customerPhone"],
      deliveryTime: json["deliveryTime"],
      discount: json["discount"],
      discountName: json["discountName"],
      emiDuration: _toInt(json["emiDuration"]),
      emiInterest: _toInt(json["emiInterest"]),
      gatewayText: json["gatewayText"],
      grossAmount: _toInt(json["grossAmount"]),
      id: _toInt(json["id"]),
      image: json["image"],
      isChargePaid: json["isChargePaid"],
      isEmi: json["isEmi"],
      isPaid: json["isPaid"],
      isSettle: json["isSettle"],
      isTransferred: json["isTransferred"],
      latitude: json["latitude"],
      logisticsCharge: json["logisticsCharge"],
      logisticsCityId: json["logisticsCityId"],
      logisticsExtraCharge: json["logisticsExtraCharge"],
      logisticsId: _toInt(json["logisticsId"]),
      logisticsIsConfirmed: json["logisticsIsConfirmed"],
      logisticsIsPaid: json["logisticsIsPaid"],
      logisticsStoppageId: json["logisticsStoppageId"],
      logisticsText: json["logisticsText"],
      logisticsUrl: json["logisticsUrl"],
      logisticsZoneId: json["logisticsZoneId"],
      longitude: json["longitude"],
      netAmount: _toInt(json["netAmount"]),
      orderId: json["orderId"],
      paid: _toInt(json["paid"]),
      paymentId: json["paymentId"],
      paymentResellerId: json["paymentResellerId"],
      profit: _toInt(json["profit"]),
      resellAmount: _toInt(json["resellAmount"]),
      resellerAdvanceCollect: _toInt(json["resellerAdvanceCollect"]),
      resellerCommission: _toInt(json["resellerCommission"]),
      resellerId: json["resellerId"],
      resellerIsPaid: json["resellerIsPaid"],
      rewardPoints: _toInt(json["rewardPoints"]),
      status: _toInt(json["status"]),
      statusCompleted: json["statusCompleted"] == null
          ? []
          : List<int>.from(json["statusCompleted"]!.map((x) => x)),
      total: _toInt(json["total"]),
      trackingId: json["trackingId"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      vat: _toInt(json["vat"]),
      vatAmount: _toInt(json["vatAmount"]),
      customer: json["customer"],
      events: json["events"] == null
          ? []
          : List<Event>.from(json["events"]!.map((x) => Event.fromJson(x))),
      lines: json["lines"] == null
          ? []
          : List<Line>.from(json["lines"]!.map((x) => Line.fromJson(x))),
    );
  }

  // Helper method to convert dynamic to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class Event {
  Event({
    required this.createdAt,
    required this.eventType,
    required this.id,
    required this.note,
  });

  final DateTime? createdAt;
  final int? eventType;
  final int? id;
  final String? note;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      eventType: _toInt(json["eventType"]),
      id: _toInt(json["id"]),
      note: json["note"],
    );
  }
  // Helper method to convert dynamic to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class Line {
  Line({
    required this.cost,
    required this.currency,
    required this.id,
    required this.image,
    required this.isActive,
    required this.productId,
    required this.productHid,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.resellPrice,
    required this.source,
    required this.unit,
    required this.price,
    required this.unitType,
    required this.variant,
    required this.vat,
  });

  final int? cost;
  final String? currency;
  final int? id;
  final String? image;
  final bool? isActive;
  final int? productId;
  final String? productHid;
  final String? productName;
  final String? productSku;
  final int? quantity;
  final int? resellPrice;
  final String? source;
  final int? unit;
  final int? price;
  final int? unitType;
  final String? variant;
  final int? vat;

  factory Line.fromJson(Map<String, dynamic> json) {
    return Line(
      cost: _toInt(json["cost"]),
      currency: json["currency"],
      id: _toInt(json["id"]),
      image: json["image"],
      isActive: json["isActive"],
      productId: _toInt(json["productId"]),
      productHid: json["productHid"],
      productName: json["productName"],
      productSku: json["productSku"],
      quantity: _toInt(json["quantity"]),
      resellPrice: _toInt(json["resellPrice"]),
      source: json["source"],
      unit: _toInt(json["unit"]),
      price: _toInt(json["price"]),
      unitType: _toInt(json["unitType"]),
      variant: json["variant"],
      vat: _toInt(json["vat"]),
    );
  }
  // Helper method to convert dynamic to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
