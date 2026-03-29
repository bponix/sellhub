import 'package:hive/hive.dart';

part 'product_res_common.g.dart';

@HiveType(typeId: 0)
class ProductResCommon {
  @HiveField(0)
  final double? affiliateCommission;

  @HiveField(1)
  final List<String> brands;

  @HiveField(2)
  final double? cashback;

  @HiveField(3)
  final double? comparePrice;

  @HiveField(4)
  final String? currency;

  @HiveField(5)
  final double? deliveryCharge;

  @HiveField(6)
  final double? discount;

  @HiveField(7)
  final bool? isExclusive;

  @HiveField(8)
  final List<Feature> features;

  @HiveField(9)
  final double? flashPrice;

  @HiveField(10)
  final String? hid;

  @HiveField(11)
  final int? id;

  @HiveField(12)
  final List<ProductImage> images;

  @HiveField(13)
  final bool? isActive;

  @HiveField(14)
  final bool? isContinueSelling;

  @HiveField(15)
  final bool? isFlash;

  @HiveField(16)
  final bool? isOneTime;

  @HiveField(17)
  final bool? isNegotiable;

  @HiveField(18)
  final bool? isVariant;

  @HiveField(19)
  final int? maxOrder;

  @HiveField(20)
  final double? maxResellPrice;

  @HiveField(21)
  final double? minResellPrice;

  @HiveField(22)
  final int? minOrder;

  @HiveField(23)
  final double? price;

  @HiveField(24)
  final int? productType;

  @HiveField(25)
  final double? quantity;

  @HiveField(26)
  final double? rating;

  @HiveField(27)
  final int? ratingTotal;

  @HiveField(28)
  final double? rewardPoints;

  @HiveField(29)
  final int? siteId;

  @HiveField(30)
  final String? sku;

  @HiveField(31)
  final String? slug;

  @HiveField(32)
  final String? thumbnail;

  @HiveField(33)
  final String? title;

  @HiveField(34)
  final String? translation;

  @HiveField(35)
  final double? unit;

  @HiveField(36)
  final int? unitType;

  @HiveField(37)
  final List<Variant> variants;

  @HiveField(38)
  final double? vat;

  @HiveField(39)
  final double? weight;

  @HiveField(40)
  final List<dynamic> wholesale;

  @HiveField(41)
  final double? wholesalePrice;

  ProductResCommon({
    this.affiliateCommission,
    required this.brands,
    this.cashback,
    this.comparePrice,
    this.currency,
    this.deliveryCharge,
    this.discount,
    this.isExclusive,
    required this.features,
    this.flashPrice,
    this.hid,
    this.id,
    required this.images,
    this.isActive,
    this.isContinueSelling,
    this.isFlash,
    this.isOneTime,
    this.isNegotiable,
    this.isVariant,
    this.maxOrder,
    this.maxResellPrice,
    this.minResellPrice,
    this.minOrder,
    this.price,
    this.productType,
    this.quantity,
    this.rating,
    this.ratingTotal,
    this.rewardPoints,
    this.siteId,
    this.sku,
    this.slug,
    this.thumbnail,
    this.title,
    this.translation,
    this.unit,
    this.unitType,
    required this.variants,
    this.vat,
    this.weight,
    required this.wholesale,
    this.wholesalePrice,
  });

  factory ProductResCommon.fromJson(Map<String, dynamic> json) {
    return ProductResCommon(
      affiliateCommission: json["affiliateCommission"],
      brands: json["brands"] == null
          ? []
          : List<String>.from(json["brands"]!.map((x) => x.toString())),
      cashback: json["cashback"],
      comparePrice: json["comparePrice"],
      currency: json["currency"],
      deliveryCharge: json["deliveryCharge"],
      discount: json["discount"],
      isExclusive: json["isExclusive"],
      features: json["features"] == null
          ? []
          : List<Feature>.from(
              json["features"]!.map((x) => Feature.fromJson(x)),
            ),
      flashPrice: json["flashPrice"],
      hid: json["hid"],
      id: json["id"],
      images: json["images"] == null
          ? []
          : List<ProductImage>.from(
              json["images"]!.map((x) => ProductImage.fromJson(x)),
            ),
      isActive: json["isActive"],
      isContinueSelling: json["isContinueSelling"],
      isFlash: json["isFlash"],
      isOneTime: json["isOneTime"],
      isNegotiable: json["isNegotiable"],
      isVariant: json["isVariant"],
      maxOrder: json["maxOrder"],
      maxResellPrice: json["maxResellPrice"],
      minResellPrice: json["minResellPrice"],
      minOrder: json["minOrder"],
      price: json["price"],
      productType: json["productType"],
      quantity: json["quantity"],
      rating: json["rating"],
      ratingTotal: json["ratingTotal"],
      rewardPoints: json["rewardPoints"],
      siteId: json["siteId"],
      sku: json["sku"],
      slug: json["slug"],
      thumbnail: json["thumbnail"],
      title: json["title"],
      translation: json["translation"],
      unit: json["unit"],
      unitType: json["unitType"],
      variants: json["variants"] == null
          ? []
          : List<Variant>.from(
              json["variants"]!.map((x) => Variant.fromJson(x)),
            ),
      vat: json["vat"],
      weight: json["weight"]?.toDouble(),
      wholesale: json["wholesale"] == null
          ? []
          : List<dynamic>.from(json["wholesale"]!.map((x) => x)),
      wholesalePrice: json["wholesalePrice"],
    );
  }

  Map<String, dynamic> toJson() => {
    "affiliateCommission": affiliateCommission,
    "brands": brands.map((x) => x).toList(),
    "cashback": cashback,
    "comparePrice": comparePrice,
    "currency": currency,
    "deliveryCharge": deliveryCharge,
    "discount": discount,
    "isExclusive": isExclusive,
    "features": features.map((x) => x.toJson()).toList(),
    "flashPrice": flashPrice,
    "hid": hid,
    "id": id,
    "images": images.map((x) => x.toJson()).toList(),
    "isActive": isActive,
    "isContinueSelling": isContinueSelling,
    "isFlash": isFlash,
    "isOneTime": isOneTime,
    "isNegotiable": isNegotiable,
    "isVariant": isVariant,
    "maxOrder": maxOrder,
    "maxResellPrice": maxResellPrice,
    "minResellPrice": minResellPrice,
    "minOrder": minOrder,
    "price": price,
    "productType": productType,
    "quantity": quantity,
    "rating": rating,
    "ratingTotal": ratingTotal,
    "rewardPoints": rewardPoints,
    "siteId": siteId,
    "sku": sku,
    "slug": slug,
    "thumbnail": thumbnail,
    "title": title,
    "translation": translation,
    "unit": unit,
    "unitType": unitType,
    "variants": variants.map((x) => x.toJson()).toList(),
    "vat": vat,
    "weight": weight,
    "wholesale": wholesale.map((x) => x).toList(),
    "wholesalePrice": wholesalePrice,
  };

  // Helper methods
  String get displayPrice => "${price ?? 0} $currency";

  String get displayComparePrice =>
      comparePrice != null ? "$comparePrice $currency" : "";

  bool get hasDiscount => discount != null && discount! > 0;

  double get discountPercentage => comparePrice != null && price != null
      ? ((comparePrice! - price!) / comparePrice! * 100)
      : 0.0;

  bool get isOutOfStock => quantity == null || quantity! <= 0;

  bool get hasVariants => isVariant == true && variants.isNotEmpty;

  List<String> get imageUrls => images.map((img) => img.image ?? "").toList();

  String get firstImage => images.isNotEmpty ? images.first.image ?? "" : "";
}

@HiveType(typeId: 1)
class Feature {
  @HiveField(0)
  final String? key;

  @HiveField(1)
  final String? value;

  Feature({this.key, this.value});

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(key: json["key"], value: json["value"]);
  }

  Map<String, dynamic> toJson() => {"key": key, "value": value};

  @override
  String toString() => "$key: $value";
}

@HiveType(typeId: 2)
class ProductImage {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String? image;

  ProductImage({this.id, this.image});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(id: json["id"], image: json["image"]);
  }

  Map<String, dynamic> toJson() => {"id": id, "image": image};

  @override
  String toString() => image ?? "";
}

@HiveType(typeId: 3)
class Variant {
  @HiveField(0)
  final double? comparePrice;

  @HiveField(1)
  final double? cost;

  @HiveField(2)
  final String? currency;

  @HiveField(3)
  final int? id;

  @HiveField(4)
  final int? imageIndex;

  @HiveField(5)
  final double? price;

  @HiveField(6)
  final int? priority;

  @HiveField(7)
  final double? quantity;

  @HiveField(8)
  final String? title;

  @HiveField(9)
  final List<Feature> variant;

  @HiveField(10)
  final double? weight;

  @HiveField(11)
  final double? wholesalePrice;

  Variant({
    this.comparePrice,
    this.cost,
    this.currency,
    this.id,
    this.imageIndex,
    this.price,
    this.priority,
    this.quantity,
    this.title,
    required this.variant,
    this.weight,
    this.wholesalePrice,
  });

  factory Variant.fromJson(Map<String, dynamic> json) {
    return Variant(
      comparePrice: json["comparePrice"],
      cost: json["cost"],
      currency: json["currency"],
      id: json["id"],
      imageIndex: json["imageIndex"],
      price: json["price"],
      priority: json["priority"],
      quantity: json["quantity"],
      title: json["title"],
      variant: json["variant"] == null
          ? []
          : List<Feature>.from(
              json["variant"]!.map((x) => Feature.fromJson(x)),
            ),
      weight: json["weight"],
      wholesalePrice: json["wholesalePrice"],
    );
  }

  Map<String, dynamic> toJson() => {
    "comparePrice": comparePrice,
    "cost": cost,
    "currency": currency,
    "id": id,
    "imageIndex": imageIndex,
    "price": price,
    "priority": priority,
    "quantity": quantity,
    "title": title,
    "variant": variant.map((x) => x.toJson()).toList(),
    "weight": weight,
    "wholesalePrice": wholesalePrice,
  };

  // Helper methods
  String get displayPrice => "${price ?? 0} $currency";

  String get displayComparePrice =>
      comparePrice != null ? "$comparePrice $currency" : "";

  bool get isOutOfStock => quantity == null || quantity! <= 0;

  String get variantName => title ?? "Variant ${id ?? ''}";
}
