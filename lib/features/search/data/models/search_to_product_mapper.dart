import 'package:sellhub/core/config/id_encoder.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';

import '../../../../core/config/app_environment.dart';

class SearchToProductMapper {
  static ProductResCommon toProduct(SearchProductRes s) {
    return ProductResCommon(
      // REQUIRED FOR CART / FAV
      id: s.id,
      hid: encodeId(s.id),
      title: s.title,
      thumbnail:
          '${AppEnvironment.mediaBaseUrl}${s.thumbnail}', // '${AppEnvironment.mediaBaseUrl}${d.thumbnail}'
      price: s.price,
      comparePrice: s.comparePrice,
      wholesalePrice: s.wholesalePrice,
      minResellPrice: s.minResellPrice,
      maxResellPrice: s.maxResellPrice,
      siteId: s.siteId,
      sku: s.sku,

      // SAFE DEFAULTS
      brands: const [],
      features: const [],
      images: [
        ProductImage(
          id: null,
          image: '${AppEnvironment.mediaBaseUrl}${s.thumbnail}',
        ),
      ],
      variants: const [],
      wholesale: const [],

      // OPTIONAL / NULL
      currency: "BDT",
      quantity: 1,
      isActive: true,
      isVariant: false,
    );
  }
}
