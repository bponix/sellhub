class ProductDetailsRes {
  ProductDetailsRes({
    required this.affiliateCommission,
    required this.affiliateCommissionPercentage,
    required this.authors,
    required this.barcode,
    required this.brands,
    required this.campaigns,
    required this.cashback,
    required this.categories,
    required this.childProducts,
    required this.collections,
    required this.comparePrice,
    required this.cost,
    required this.createdAt,
    required this.createdById,
    required this.currency,
    required this.deliveryCharge,
    required this.deliveryTime,
    required this.description,
    required this.discount,
    required this.emiDuration,
    required this.emiInterest,
    required this.emiPrice,
    required this.extraImages,
    required this.faq,
    required this.features,
    required this.file,
    required this.fileType,
    required this.flashPrice,
    //required this.html,
    required this.id,
    required this.hid,
    required this.image,
    required this.images,
    required this.isActive,
    required this.isCod,
    required this.isContinueSelling,
    required this.isEmi,
    required this.isExclusive,
    required this.isFeatured,
    required this.isFlash,
    required this.isNegotiable,
    required this.isNew,
    required this.isOneTime,
    required this.isPrivate,
    required this.isResell,
    required this.isTrack,
    required this.isVariant,
    required this.isWarranty,
    required this.keyword,
    required this.maxOrder,
    required this.maxResellPrice,
    required this.minResellPrice,
    required this.metaDescription,
    required this.metaTitle,
    required this.minOrder,
    required this.note,
    required this.parentId,
    required this.price,
    required this.priority,
    required this.productType,
    required this.quantity,
    required this.requirements,
    required this.rewardPoints,
    required this.salePrice,
    required this.shops,
    required this.siteId,
    required this.sku,
    required this.slug,
    required this.sold,
    required this.source,
    required this.stoppages,
    required this.subCategories,
    required this.subSubCategories,
    required this.supplierId,
    required this.tags,
    required this.thumbnail,
    required this.title,
    required this.translation,
    required this.unit,
    required this.unitType,
    required this.updatedAt,
    required this.updatedById,
    required this.validFor,
    required this.vat,
    required this.variants,
    required this.vouchers,
    required this.warranty,
    required this.weight,
    required this.wholesale,
    required this.wholesalePrice,
    required this.wholesalePricePercentage,
  });

  final double? affiliateCommission;
  final double? affiliateCommissionPercentage;
  final List<dynamic> authors;
  final String? barcode;
  final List<dynamic> brands;
  final List<dynamic> campaigns;
  final double? cashback;
  final List<int> categories;
  final List<dynamic> childProducts;
  final List<dynamic> collections;
  final double? comparePrice;
  final double? cost;
  final DateTime? createdAt;
  final int? createdById;
  final String? currency;
  final double? deliveryCharge;
  final int? deliveryTime;
  final String? description;
  final double? discount;
  final int? emiDuration;
  final double? emiInterest;
  final double? emiPrice;
  final List<dynamic> extraImages;
  final List<dynamic> faq;
  final List<Feature> features;
  final String? file;
  final String? fileType;
  final double? flashPrice;
  // final Html? html;
  final int? id;
  final String? hid;
  final String? image;
  final List<ProductDetailsImage> images;
  final bool? isActive;
  final bool? isCod;
  final bool? isContinueSelling;
  final bool? isEmi;
  final bool? isExclusive;
  final bool? isFeatured;
  final bool? isFlash;
  final bool? isNegotiable;
  final bool? isNew;
  final bool? isOneTime;
  final bool? isPrivate;
  final bool? isResell;
  final bool? isTrack;
  final bool? isVariant;
  final bool? isWarranty;
  final String? keyword;
  final int? maxOrder;
  final double? maxResellPrice;
  final double? minResellPrice;
  final String? metaDescription;
  final String? metaTitle;
  final int? minOrder;
  final List<dynamic> note;
  final dynamic parentId;
  final double? price;
  final int? priority;
  final int? productType;
  final double? quantity;
  final List<dynamic> requirements;
  final double? rewardPoints;
  final double? salePrice;
  final List<dynamic> shops;
  final int? siteId;
  final String? sku;
  final String? slug;
  final double? sold;
  final String? source;
  final List<dynamic> stoppages;
  final List<dynamic> subCategories;
  final List<dynamic> subSubCategories;
  final dynamic supplierId;
  final List<dynamic> tags;
  final String? thumbnail;
  final String? title;
  final String? translation;
  final double? unit;
  final int? unitType;
  final DateTime? updatedAt;
  final int? updatedById;
  final int? validFor;
  final double? vat;
  final List<ProductDetailsResVariant> variants;
  final List<dynamic> vouchers;
  final dynamic warranty;
  final double? weight;
  final List<dynamic> wholesale;
  final double? wholesalePrice;
  final double? wholesalePricePercentage;

  factory ProductDetailsRes.fromJson(Map<String, dynamic> json) {
    return ProductDetailsRes(
      affiliateCommission: json["affiliateCommission"],
      affiliateCommissionPercentage: json["affiliateCommissionPercentage"],
      authors: json["authors"] == null
          ? []
          : List<dynamic>.from(json["authors"]!.map((x) => x)),
      barcode: json["barcode"],
      brands: json["brands"] == null
          ? []
          : List<dynamic>.from(json["brands"]!.map((x) => x)),
      campaigns: json["campaigns"] == null
          ? []
          : List<dynamic>.from(json["campaigns"]!.map((x) => x)),
      cashback: json["cashback"],
      categories: json["categories"] == null
          ? []
          : List<int>.from(json["categories"]!.map((x) => x)),
      childProducts: json["childProducts"] == null
          ? []
          : List<dynamic>.from(json["childProducts"]!.map((x) => x)),
      collections: json["collections"] == null
          ? []
          : List<dynamic>.from(json["collections"]!.map((x) => x)),
      comparePrice: json["comparePrice"],
      cost: json["cost"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      createdById: json["createdById"],
      currency: json["currency"],
      deliveryCharge: json["deliveryCharge"],
      deliveryTime: json["deliveryTime"],
      description: json["description"],
      discount: json["discount"],
      emiDuration: json["emiDuration"],
      emiInterest: json["emiInterest"],
      emiPrice: json["emiPrice"],
      extraImages: json["extraImages"] == null
          ? []
          : List<dynamic>.from(json["extraImages"]!.map((x) => x)),
      faq: json["faq"] == null
          ? []
          : List<dynamic>.from(json["faq"]!.map((x) => x)),
      features: json["features"] == null
          ? []
          : List<Feature>.from(
              json["features"]!.map((x) => Feature.fromJson(x)),
            ),
      file: json["file"],
      fileType: json["fileType"],
      flashPrice: json["flashPrice"],
      //html: json["html"] == null ? null : Html.fromJson(json["html"]),
      id: json["id"],
      hid: json["hid"],
      image: json["image"],
      images: json["images"] == null
          ? []
          : List<ProductDetailsImage>.from(
              json["images"]!.map((x) => ProductDetailsImage.fromJson(x)),
            ),
      isActive: json["isActive"],
      isCod: json["isCod"],
      isContinueSelling: json["isContinueSelling"],
      isEmi: json["isEmi"],
      isExclusive: json["isExclusive"],
      isFeatured: json["isFeatured"],
      isFlash: json["isFlash"],
      isNegotiable: json["isNegotiable"],
      isNew: json["isNew"],
      isOneTime: json["isOneTime"],
      isPrivate: json["isPrivate"],
      isResell: json["isResell"],
      isTrack: json["isTrack"],
      isVariant: json["isVariant"],
      isWarranty: json["isWarranty"],
      keyword: json["keyword"],
      maxOrder: json["maxOrder"],
      maxResellPrice: json["maxResellPrice"],
      minResellPrice: json["minResellPrice"],
      metaDescription: json["metaDescription"],
      metaTitle: json["metaTitle"],
      minOrder: json["minOrder"],
      note: json["note"] == null
          ? []
          : List<dynamic>.from(json["note"]!.map((x) => x)),
      parentId: json["parentId"],
      price: json["price"],
      priority: json["priority"],
      productType: json["productType"],
      quantity: json["quantity"],
      requirements: json["requirements"] == null
          ? []
          : List<dynamic>.from(json["requirements"]!.map((x) => x)),
      rewardPoints: json["rewardPoints"],
      salePrice: json["salePrice"],
      shops: json["shops"] == null
          ? []
          : List<dynamic>.from(json["shops"]!.map((x) => x)),
      siteId: json["siteId"],
      sku: json["sku"],
      slug: json["slug"],
      sold: json["sold"],
      source: json["source"],
      stoppages: json["stoppages"] == null
          ? []
          : List<dynamic>.from(json["stoppages"]!.map((x) => x)),
      subCategories: json["subCategories"] == null
          ? []
          : List<dynamic>.from(json["subCategories"]!.map((x) => x)),
      subSubCategories: json["subSubCategories"] == null
          ? []
          : List<dynamic>.from(json["subSubCategories"]!.map((x) => x)),
      supplierId: json["supplierId"],
      tags: json["tags"] == null
          ? []
          : List<dynamic>.from(json["tags"]!.map((x) => x)),
      thumbnail: json["thumbnail"],
      title: json["title"],
      translation: json["translation"],
      unit: json["unit"],
      unitType: json["unitType"],
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      updatedById: json["updatedById"],
      validFor: json["validFor"],
      vat: json["vat"],
      variants: json["variants"] == null
          ? []
          : List<ProductDetailsResVariant>.from(
              json["variants"]!.map(
                (x) => ProductDetailsResVariant.fromJson(x),
              ),
            ),
      vouchers: json["vouchers"] == null
          ? []
          : List<dynamic>.from(json["vouchers"]!.map((x) => x)),
      warranty: json["warranty"],
      weight: json["weight"],
      wholesale: json["wholesale"] == null
          ? []
          : List<dynamic>.from(json["wholesale"]!.map((x) => x)),
      wholesalePrice: json["wholesalePrice"],
      wholesalePricePercentage: json["wholesalePricePercentage"],
    );
  }

  Map<String, dynamic> toJson() => {
    "affiliateCommission": affiliateCommission,
    "affiliateCommissionPercentage": affiliateCommissionPercentage,
    "authors": authors.map((x) => x).toList(),
    "barcode": barcode,
    "brands": brands.map((x) => x).toList(),
    "campaigns": campaigns.map((x) => x).toList(),
    "cashback": cashback,
    "categories": categories.map((x) => x).toList(),
    "childProducts": childProducts.map((x) => x).toList(),
    "collections": collections.map((x) => x).toList(),
    "comparePrice": comparePrice,
    "cost": cost,
    "createdAt": createdAt?.toIso8601String(),
    "createdById": createdById,
    "currency": currency,
    "deliveryCharge": deliveryCharge,
    "deliveryTime": deliveryTime,
    "description": description,
    "discount": discount,
    "emiDuration": emiDuration,
    "emiInterest": emiInterest,
    "emiPrice": emiPrice,
    "extraImages": extraImages.map((x) => x).toList(),
    "faq": faq.map((x) => x).toList(),
    "features": features.map((x) => x.toJson()).toList(),
    "file": file,
    "fileType": fileType,
    "flashPrice": flashPrice,
    //"html": html?.toJson(),
    "id": id,
    "hid": hid,
    "image": image,
    "images": images.map((x) => x.toJson()).toList(),
    "isActive": isActive,
    "isCod": isCod,
    "isContinueSelling": isContinueSelling,
    "isEmi": isEmi,
    "isExclusive": isExclusive,
    "isFeatured": isFeatured,
    "isFlash": isFlash,
    "isNegotiable": isNegotiable,
    "isNew": isNew,
    "isOneTime": isOneTime,
    "isPrivate": isPrivate,
    "isResell": isResell,
    "isTrack": isTrack,
    "isVariant": isVariant,
    "isWarranty": isWarranty,
    "keyword": keyword,
    "maxOrder": maxOrder,
    "maxResellPrice": maxResellPrice,
    "minResellPrice": minResellPrice,
    "metaDescription": metaDescription,
    "metaTitle": metaTitle,
    "minOrder": minOrder,
    "note": note.map((x) => x).toList(),
    "parentId": parentId,
    "price": price,
    "priority": priority,
    "productType": productType,
    "quantity": quantity,
    "requirements": requirements.map((x) => x).toList(),
    "rewardPoints": rewardPoints,
    "salePrice": salePrice,
    "shops": shops.map((x) => x).toList(),
    "siteId": siteId,
    "sku": sku,
    "slug": slug,
    "sold": sold,
    "source": source,
    "stoppages": stoppages.map((x) => x).toList(),
    "subCategories": subCategories.map((x) => x).toList(),
    "subSubCategories": subSubCategories.map((x) => x).toList(),
    "supplierId": supplierId,
    "tags": tags.map((x) => x).toList(),
    "thumbnail": thumbnail,
    "title": title,
    "translation": translation,
    "unit": unit,
    "unitType": unitType,
    "updatedAt": updatedAt?.toIso8601String(),
    "updatedById": updatedById,
    "validFor": validFor,
    "vat": vat,
    "variants": variants.map((x) => x.toJson()).toList(),
    "vouchers": vouchers.map((x) => x).toList(),
    "warranty": warranty,
    "weight": weight,
    "wholesale": wholesale.map((x) => x).toList(),
    "wholesalePrice": wholesalePrice,
    "wholesalePricePercentage": wholesalePricePercentage,
  };
}

class Feature {
  Feature({required this.id, required this.key, required this.value});

  final int? id;
  final String? key;
  final String? value;

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(id: json["id"], key: json["key"], value: json["value"]);
  }

  Map<String, dynamic> toJson() => {"id": id, "key": key, "value": value};
}

class Html {
  Html({required this.blocks, required this.time, required this.version});

  final List<dynamic> blocks;
  final int? time;
  final String? version;

  factory Html.fromJson(Map<String, dynamic> json) {
    return Html(
      blocks: json["blocks"] == null
          ? []
          : List<dynamic>.from(json["blocks"]!.map((x) => x)),
      time: json["time"],
      version: json["version"],
    );
  }

  Map<String, dynamic> toJson() => {
    "blocks": blocks.map((x) => x).toList(),
    "time": time,
    "version": version,
  };
}

class ProductDetailsImage {
  ProductDetailsImage({required this.id, required this.image});

  final int? id;
  final String? image;

  factory ProductDetailsImage.fromJson(Map<String, dynamic> json) {
    return ProductDetailsImage(id: json["id"], image: json["image"]);
  }

  Map<String, dynamic> toJson() => {"id": id, "image": image};
}

class ProductDetailsResVariant {
  ProductDetailsResVariant({
    required this.comparePrice,
    required this.cost,
    required this.currency,
    required this.id,
    required this.imageIndex,
    required this.price,
    required this.priority,
    required this.quantity,
    required this.title,
    required this.variant,
    required this.weight,
    required this.wholesalePrice,
  });

  final double? comparePrice;
  final double? cost;
  final String? currency;
  final int? id;
  final int? imageIndex;
  final double? price;
  final int? priority;
  final double? quantity;
  final String? title;
  final List<VariantVariant> variant;
  final double? weight;
  final double? wholesalePrice;

  factory ProductDetailsResVariant.fromJson(Map<String, dynamic> json) {
    return ProductDetailsResVariant(
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
          : List<VariantVariant>.from(
              json["variant"]!.map((x) => VariantVariant.fromJson(x)),
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
}

class VariantVariant {
  VariantVariant({required this.key, required this.value});

  final String? key;
  final String? value;

  factory VariantVariant.fromJson(Map<String, dynamic> json) {
    return VariantVariant(key: json["key"], value: json["value"]);
  }

  Map<String, dynamic> toJson() => {"key": key, "value": value};
}
