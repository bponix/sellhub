import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/product_details_to_common_mapper.dart';

extension ProductMerge on ProductResCommon {
  ProductResCommon mergeDetails(ProductDetailsRes remote) {
    return ProductDetailsToCommonMapper.map(remote, this);
  }
}
