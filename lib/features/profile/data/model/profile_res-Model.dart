class ProfileResModel {
  ProfileResModel({
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
    required this.note,
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

  final double? affiliatePaid;
  final double? affiliateProcessing;
  final double? affiliateTotal;
  final double? affiliatePayable;
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
  final dynamic note;
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
  final double? pendingBalance;
  final double? pendingCashbackBalance;
  final double? pendingGiftCardBalance;
  final double? pendingProfit;
  final double? pendingPurchase;
  final double? pendingRewardPoints;
  final int? phone;
  final String? referCode;
  final int? referId;
  final double? resellPaid;
  final double? resellProcessing;
  final double? resellTotal;
  final double? resellPayable;
  final String? tags;
  final List<dynamic> shippingAddress;
  final int? siteId;
  final String? title;
  final double? totalBalance;
  final double? totalCashbackBalance;
  final double? totalGiftCardBalance;
  final double? totalPaid;
  final double? totalProfit;
  final double? totalPurchase;
  final double? totalReturnCharge;
  final double? totalRewardPoints;
  final DateTime? updatedAt;
  final int? userId;

  factory ProfileResModel.fromJson(Map<String, dynamic> json) {
    return ProfileResModel(
      affiliatePaid: json["affiliatePaid"],
      affiliateProcessing: json["affiliateProcessing"],
      affiliateTotal: json["affiliateTotal"],
      affiliatePayable: json["affiliatePayable"],
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
      customerType: json["customerType"],
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
      id: json["id"],
      isActive: json["isActive"],
      isAffiliate: json["isAffiliate"],
      isAffiliateCommission: json["isAffiliateCommission"],
      isAffiliateJoin: json["isAffiliateJoin"],
      isReseller: json["isReseller"],
      isWholesale: json["isWholesale"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      nid: json["nid"],
      note: json["note"],
      ordersCancelled: json["ordersCancelled"],
      ordersConfirmed: json["ordersConfirmed"],
      ordersDelivered: json["ordersDelivered"],
      ordersOnTheWay: json["ordersOnTheWay"],
      ordersPackaging: json["ordersPackaging"],
      ordersPending: json["ordersPending"],
      ordersPlaced: json["ordersPlaced"],
      ordersRejected: json["ordersRejected"],
      ordersReturned: json["ordersReturned"],
      ordersShipment: json["ordersShipment"],
      ordersStation: json["ordersStation"],
      ordersTotal: json["ordersTotal"],
      paymentNo: json["paymentNo"],
      paymentTitle: json["paymentTitle"],
      pendingBalance: json["pendingBalance"],
      pendingCashbackBalance: json["pendingCashbackBalance"],
      pendingGiftCardBalance: json["pendingGiftCardBalance"],
      pendingProfit: json["pendingProfit"],
      pendingPurchase: json["pendingPurchase"],
      pendingRewardPoints: json["pendingRewardPoints"],
      phone: json["phone"],
      referCode: json["referCode"],
      referId: json["referId"],
      resellPaid: json["resellPaid"],
      resellProcessing: json["resellProcessing"],
      resellTotal: json["resellTotal"],
      resellPayable: json["resellPayable"],
      tags: json["tags"],
      shippingAddress: json["shippingAddress"] == null
          ? []
          : List<dynamic>.from(json["shippingAddress"]!.map((x) => x)),
      siteId: json["siteId"],
      title: json["title"],
      totalBalance: json["totalBalance"],
      totalCashbackBalance: json["totalCashbackBalance"],
      totalGiftCardBalance: json["totalGiftCardBalance"],
      totalPaid: json["totalPaid"],
      totalProfit: json["totalProfit"],
      totalPurchase: json["totalPurchase"],
      totalReturnCharge: json["totalReturnCharge"],
      totalRewardPoints: json["totalRewardPoints"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      userId: json["userId"],
    );
  }
}
