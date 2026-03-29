import '../../../product/data/models/product_details.dart';
import '../../../product/data/models/product_res_common.dart';

class ProductDetailsToCommonMapper {
  static ProductResCommon map(ProductDetailsRes d, ProductResCommon base) {
    return ProductResCommon(
      affiliateCommission: d.affiliateCommission ?? base.affiliateCommission,

      // 🔴 FIX: dynamic → String
      brands: d.brands.map((e) => e.toString()).toList(),

      cashback: d.cashback ?? base.cashback,
      comparePrice: d.comparePrice ?? base.comparePrice,
      currency: d.currency ?? base.currency,
      deliveryCharge: d.deliveryCharge ?? base.deliveryCharge,
      discount: d.discount ?? base.discount,
      isExclusive: d.isExclusive ?? base.isExclusive,

      flashPrice: d.flashPrice ?? base.flashPrice,
      hid: d.hid ?? base.hid,
      id: d.id ?? base.id,

      // 🔴 ProductDetailsImage → ProductImage
      images: d.images.isNotEmpty
          ? d.images.map((e) => ProductImage(id: e.id, image: e.image)).toList()
          : base.images,

      isActive: d.isActive ?? base.isActive,
      isContinueSelling: d.isContinueSelling ?? base.isContinueSelling,
      isFlash: d.isFlash ?? base.isFlash,
      isOneTime: d.isOneTime ?? base.isOneTime,
      isNegotiable: d.isNegotiable ?? base.isNegotiable,
      isVariant: d.isVariant ?? base.isVariant,

      maxOrder: d.maxOrder ?? base.maxOrder,
      maxResellPrice: d.maxResellPrice ?? base.maxResellPrice,
      minResellPrice: d.minResellPrice ?? base.minResellPrice,
      minOrder: d.minOrder ?? base.minOrder,

      price: d.price ?? base.price,
      productType: d.productType ?? base.productType,
      quantity: d.quantity ?? base.quantity,

      // ❌ ProductDetailsRes has NO rating
      rating: base.rating,
      ratingTotal: base.ratingTotal,

      rewardPoints: d.rewardPoints ?? base.rewardPoints,
      siteId: d.siteId ?? base.siteId,
      sku: d.sku ?? base.sku,
      slug: d.slug ?? base.slug,
      thumbnail:
          d.thumbnail ??
          base.thumbnail, //  '${AppEnvironment.mediaBaseUrl}${d.thumbnail}'
      title: d.title ?? base.title,
      translation: d.translation ?? base.translation,
      unit: d.unit ?? base.unit,
      unitType: d.unitType ?? base.unitType,

      vat: d.vat ?? base.vat,
      weight: d.weight ?? base.weight,
      wholesale: d.wholesale.isNotEmpty ? d.wholesale : base.wholesale,
      wholesalePrice: d.wholesalePrice ?? base.wholesalePrice,
      features: [],
      variants: [],
    );
  }
}
