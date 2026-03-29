class ResellerResModelProfile {
  ResellerResModelProfile({
    required this.affiliatePaid,
    required this.affiliateProcessing,
    required this.affiliateTotal,
    required this.affiliatePayable,
    required this.address,
    required this.avatar,
    required this.billingAddress,
    required this.blockProducts,
    required this.createdAt,
    required this.currency,
    required this.customerType,
    required this.customerTypes,
    required this.cartProducts,
    required this.domain,
    required this.favorite,
    required this.formattedAddress,
    required this.id,
    required this.isActive,
    required this.isAffiliate,
    required this.isAffiliateCommission,
    required this.isAffiliateJoin,
    required this.isReseller,
    required this.isWholesale,
    required this.latitude,
    required this.longitude,
    required this.nid,
    required this.ordersCancelled,
    required this.ordersConfirmed,
    required this.ordersDelivered,
    required this.ordersOnTheWay,
    required this.ordersPackaging,
    required this.ordersPending,
    required this.ordersPlaced,
    required this.ordersRejected,
    required this.ordersReturned,
    required this.ordersShipment,
    required this.ordersStation,
    required this.ordersTotal,
    required this.paymentNo,
    required this.paymentTitle,
    required this.pendingBalance,
    required this.pendingCashbackBalance,
    required this.pendingGiftCardBalance,
    required this.pendingProfit,
    required this.pendingPurchase,
    required this.pendingRewardPoints,
    required this.phone,
    required this.referCode,
    required this.referId,
    required this.resellPaid,
    required this.resellProcessing,
    required this.resellTotal,
    required this.resellPayable,
    required this.tags,
    required this.shippingAddress,
    required this.siteId,
    required this.title,
    required this.totalBalance,
    required this.totalCashbackBalance,
    required this.totalGiftCardBalance,
    required this.totalPaid,
    required this.totalProfit,
    required this.totalPurchase,
    required this.totalReturnCharge,
    required this.totalRewardPoints,
    required this.updatedAt,
    required this.userId,
  });

  final int? affiliatePaid;
  final int? affiliateProcessing;
  final int? affiliateTotal;
  final int? affiliatePayable;
  final String? address;
  final String? avatar;
  final List<dynamic> billingAddress;
  final List<dynamic> blockProducts;
  final DateTime? createdAt;
  final String? currency;
  final int? customerType;
  final List<int> customerTypes;
  final List<dynamic> cartProducts;
  final String? domain;
  final List<int> favorite;
  final String? formattedAddress;
  final int? id;
  final bool? isActive;
  final bool? isAffiliate;
  final bool? isAffiliateCommission;
  final bool? isAffiliateJoin;
  final bool? isReseller;
  final bool? isWholesale;
  final double? latitude;
  final double? longitude;
  final int? nid;
  final int? ordersCancelled;
  final int? ordersConfirmed;
  final int? ordersDelivered;
  final int? ordersOnTheWay;
  final int? ordersPackaging;
  final int? ordersPending;
  final int? ordersPlaced;
  final int? ordersRejected;
  final int? ordersReturned;
  final int? ordersShipment;
  final int? ordersStation;
  final int? ordersTotal;
  final String? paymentNo;
  final String? paymentTitle;
  final int? pendingBalance;
  final int? pendingCashbackBalance;
  final int? pendingGiftCardBalance;
  final int? pendingProfit;
  final int? pendingPurchase;
  final int? pendingRewardPoints;
  final int? phone;
  final String? referCode;
  final int? referId;
  final int? resellPaid;
  final int? resellProcessing;
  final int? resellTotal;
  final int? resellPayable;
  final String? tags;
  final List<dynamic> shippingAddress;
  final int? siteId;
  final String? title;
  final int? totalBalance;
  final int? totalCashbackBalance;
  final int? totalGiftCardBalance;
  final int? totalPaid;
  final int? totalProfit;
  final int? totalPurchase;
  final int? totalReturnCharge;
  final int? totalRewardPoints;
  final DateTime? updatedAt;
  final int? userId;

  factory ResellerResModelProfile.fromJson(Map<String, dynamic> json) {
    return ResellerResModelProfile(
      affiliatePaid: _toInt(json["affiliatePaid"]),
      affiliateProcessing: _toInt(json["affiliateProcessing"]),
      affiliateTotal: _toInt(json["affiliateTotal"]),
      affiliatePayable: _toInt(json["affiliatePayable"]),
      address: json["address"],
      avatar: json["avatar"],
      billingAddress: json["billingAddress"] == null
          ? []
          : List<dynamic>.from(json["billingAddress"]!.map((x) => x)),
      blockProducts: json["blockProducts"] == null
          ? []
          : List<dynamic>.from(json["blockProducts"]!.map((x) => x)),
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      currency: json["currency"],
      customerType: _toInt(json["customerType"]),
      customerTypes: json["customerTypes"] == null
          ? []
          : List<int>.from(json["customerTypes"]!.map((x) => x)),
      cartProducts: json["cartProducts"] == null
          ? []
          : List<dynamic>.from(json["cartProducts"]!.map((x) => x)),
      domain: json["domain"],
      favorite: json["favorite"] == null
          ? []
          : List<int>.from(json["favorite"]!.map((x) => x)),
      formattedAddress: json["formattedAddress"],
      id: _toInt(json["id"]),
      isActive: json["isActive"],
      isAffiliate: json["isAffiliate"],
      isAffiliateCommission: json["isAffiliateCommission"],
      isAffiliateJoin: json["isAffiliateJoin"],
      isReseller: json["isReseller"],
      isWholesale: json["isWholesale"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      nid: _toInt(json["nid"]),
      ordersCancelled: _toInt(json["ordersCancelled"]),
      ordersConfirmed: _toInt(json["ordersConfirmed"]),
      ordersDelivered: _toInt(json["ordersDelivered"]),
      ordersOnTheWay: _toInt(json["ordersOnTheWay"]),
      ordersPackaging: _toInt(json["ordersPackaging"]),
      ordersPending: _toInt(json["ordersPending"]),
      ordersPlaced: _toInt(json["ordersPlaced"]),
      ordersRejected: _toInt(json["ordersRejected"]),
      ordersReturned: _toInt(json["ordersReturned"]),
      ordersShipment: _toInt(json["ordersShipment"]),
      ordersStation: _toInt(json["ordersStation"]),
      ordersTotal: _toInt(json["ordersTotal"]),
      paymentNo: json["paymentNo"],
      paymentTitle: json["paymentTitle"],
      pendingBalance: _toInt(json["pendingBalance"]),
      pendingCashbackBalance: _toInt(json["pendingCashbackBalance"]),
      pendingGiftCardBalance: _toInt(json["pendingGiftCardBalance"]),
      pendingProfit: _toInt(json["pendingProfit"]),
      pendingPurchase: _toInt(json["pendingPurchase"]),
      pendingRewardPoints: _toInt(json["pendingRewardPoints"]),
      phone: _toInt(json["phone"]),
      referCode: json["referCode"],
      referId: _toInt(json["referId"]),
      resellPaid: _toInt(json["resellPaid"]),
      resellProcessing: _toInt(json["resellProcessing"]),
      resellTotal: _toInt(json["resellTotal"]),
      resellPayable: _toInt(json["resellPayable"]),
      tags: json["tags"],
      shippingAddress: json["shippingAddress"] == null
          ? []
          : List<dynamic>.from(json["shippingAddress"]!.map((x) => x)),
      siteId: _toInt(json["siteId"]),
      title: json["title"],
      totalBalance: _toInt(json["totalBalance"]),
      totalCashbackBalance: _toInt(json["totalCashbackBalance"]),
      totalGiftCardBalance: _toInt(json["totalGiftCardBalance"]),
      totalPaid: _toInt(json["totalPaid"]),
      totalProfit: _toInt(json["totalProfit"]),
      totalPurchase: _toInt(json["totalPurchase"]),
      totalReturnCharge: _toInt(json["totalReturnCharge"]),
      totalRewardPoints: _toInt(json["totalRewardPoints"]),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      userId: _toInt(json["userId"]),
    );
  }
  // helper method to convert dynamic to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
