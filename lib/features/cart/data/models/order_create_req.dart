class OrderCreateReq {
  OrderCreateReq({
    required this.userId,
    required this.siteId,
    required this.address,
    required this.affiliateCommission,
    required this.browser,
    required this.cashbackBalance,
    required this.charge,
    required this.cost,
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
    required this.image,
    required this.isEmi,
    required this.isRenew,
    required this.latitude,
    required this.logisticsCharge,
    required this.logisticsExtraCharge,
    required this.logisticsId,
    required this.logisticsStoppageId,
    required this.logisticsText,
    required this.longitude,
    required this.netAmount,
    required this.otp,
    required this.paid,
    required this.parentSiteId,
    required this.productId,
    required this.products,
    required this.profit,
    required this.referCode,
    required this.resellAmount,
    required this.resellerAdvanceCollect,
    required this.resellerCommission,
    required this.rewardPoints,
    required this.shopId,
    required this.sourceId,
    required this.source,
    required this.staffId,
    required this.subscription,
    required this.subscriptionFee,
    required this.total,
    required this.validTill,
    required this.vat,
    required this.vatAmount,
    required this.weight,
    this.idempotencyKey,
  });

  final dynamic userId;
  final int? siteId;
  final String? address;
  final int? affiliateCommission;
  final String? browser;
  final int? cashbackBalance;
  final int? charge;
  final int? cost;
  final String? currency;
  final String? customerAddress;
  final int? customerId;
  final String? customerName;
  final String? customerNote;
  final int? customerPhone;
  final dynamic deliveryTime;
  final int? discount;
  final String? discountName;
  final int? emiDuration;
  final int? emiInterest;
  final String? gatewayText;
  final int? grossAmount;
  final dynamic image;
  final bool? isEmi;
  final bool? isRenew;
  final double? latitude;
  final int? logisticsCharge;
  final int? logisticsExtraCharge;
  final int? logisticsId;
  final dynamic logisticsStoppageId;
  final String? logisticsText;
  final double? longitude;
  final int? netAmount;
  final int? otp;
  final int? paid;
  final dynamic parentSiteId;
  final int? productId;
  final List<ProductOrderCreate> products;
  final int? profit;
  final String? referCode;
  final int? resellAmount;
  final int? resellerAdvanceCollect;
  final int? resellerCommission;
  final int? rewardPoints;
  final dynamic shopId;
  final int? sourceId;
  final String? source;
  final dynamic staffId;
  final dynamic subscription;
  final dynamic subscriptionFee;
  final int? total;
  final dynamic validTill;
  final int? vat;
  final int? vatAmount;
  final int? weight;
  final String? idempotencyKey;

  factory OrderCreateReq.fromJson(Map<String, dynamic> json) {
    return OrderCreateReq(
      userId: json["userId"],
      siteId: json["siteId"],
      address: json["address"],
      affiliateCommission: json["affiliateCommission"],
      browser: json["browser"],
      cashbackBalance: json["cashbackBalance"],
      charge: json["charge"],
      cost: json["cost"],
      currency: json["currency"],
      customerAddress: json["customerAddress"],
      customerId: json["customerId"],
      customerName: json["customerName"],
      customerNote: json["customerNote"],
      customerPhone: json["customerPhone"],
      deliveryTime: json["deliveryTime"],
      discount: json["discount"],
      discountName: json["discountName"],
      emiDuration: json["emiDuration"],
      emiInterest: json["emiInterest"],
      gatewayText: json["gatewayText"],
      grossAmount: json["grossAmount"],
      image: json["image"],
      isEmi: json["isEmi"],
      isRenew: json["isRenew"],
      latitude: json["latitude"],
      logisticsCharge: json["logisticsCharge"],
      logisticsExtraCharge: json["logisticsExtraCharge"],
      logisticsId: json["logisticsId"],
      logisticsStoppageId: json["logisticsStoppageId"],
      logisticsText: json["logisticsText"],
      longitude: json["longitude"],
      netAmount: json["netAmount"],
      otp: json["otp"],
      paid: json["paid"],
      parentSiteId: json["parentSiteId"],
      productId: json["productId"],
      products: json["products"] == null
          ? []
          : List<ProductOrderCreate>.from(
              json["products"]!.map((x) => ProductOrderCreate.fromJson(x)),
            ),
      profit: json["profit"],
      referCode: json["referCode"],
      resellAmount: json["resellAmount"],
      resellerAdvanceCollect: json["resellerAdvanceCollect"],
      resellerCommission: json["resellerCommission"],
      rewardPoints: json["rewardPoints"],
      shopId: json["shopId"],
      sourceId: json["sourceId"],
      source: json["source"],
      staffId: json["staffId"],
      subscription: json["subscription"],
      subscriptionFee: json["subscriptionFee"],
      total: json["total"],
      validTill: json["validTill"],
      vat: json["vat"],
      vatAmount: json["vatAmount"],
      weight: json["weight"],
      idempotencyKey: json["idempotencyKey"] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    "userId": userId,
    "siteId": siteId,
    "address": address,
    "affiliateCommission": affiliateCommission,
    "browser": browser,
    "cashbackBalance": cashbackBalance,
    "charge": charge,
    "cost": cost,
    "currency": currency,
    "customerAddress": customerAddress,
    "customerId": customerId,
    "customerName": customerName,
    "customerNote": customerNote,
    "customerPhone": customerPhone,
    "deliveryTime": deliveryTime,
    "discount": discount,
    "discountName": discountName,
    "emiDuration": emiDuration,
    "emiInterest": emiInterest,
    "gatewayText": gatewayText,
    "grossAmount": grossAmount,
    "image": image,
    "isEmi": isEmi,
    "isRenew": isRenew,
    "latitude": latitude,
    "logisticsCharge": logisticsCharge,
    "logisticsExtraCharge": logisticsExtraCharge,
    "logisticsId": logisticsId,
    "logisticsStoppageId": logisticsStoppageId,
    "logisticsText": logisticsText,
    "longitude": longitude,
    "netAmount": netAmount,
    "otp": otp,
    "paid": paid,
    "parentSiteId": parentSiteId,
    "productId": productId,
    "products": products.map((x) => x.toJson()).toList(),
    "profit": profit,
    "referCode": referCode,
    "resellAmount": resellAmount,
    "resellerAdvanceCollect": resellerAdvanceCollect,
    "resellerCommission": resellerCommission,
    "rewardPoints": rewardPoints,
    "shopId": shopId,
    "sourceId": sourceId,
    "source": source,
    "staffId": staffId,
    "subscription": subscription,
    "subscriptionFee": subscriptionFee,
    "total": total,
    "validTill": validTill,
    "vat": vat,
    "vatAmount": vatAmount,
    "weight": weight,
    "idempotencyKey": idempotencyKey,
  };
}

class ProductOrderCreate {
  ProductOrderCreate({
    required this.cost,
    required this.id,
    required this.price,
    required this.quantity,
    required this.resellPrice,
    required this.thumbnail,
    required this.title,
    required this.variant,
    required this.variantId,
    required this.vat,
  });

  final int? cost;
  final int? id;
  final int? price;
  final int? quantity;
  final int? resellPrice;
  final String? thumbnail;
  final String? title;
  final String? variant;
  final dynamic variantId;
  final int? vat;

  factory ProductOrderCreate.fromJson(Map<String, dynamic> json) {
    return ProductOrderCreate(
      cost: json["cost"],
      id: json["id"],
      price: json["price"],
      quantity: json["quantity"],
      resellPrice: json["resellPrice"],
      thumbnail: json["thumbnail"],
      title: json["title"],
      variant: json["variant"],
      variantId: json["variantId"],
      vat: json["vat"],
    );
  }

  Map<String, dynamic> toJson() => {
    "cost": cost,
    "id": id,
    "price": price,
    "quantity": quantity,
    "resellPrice": resellPrice,
    "thumbnail": thumbnail,
    "title": title,
    "variant": variant,
    "variantId": variantId,
    "vat": vat,
  };
}
