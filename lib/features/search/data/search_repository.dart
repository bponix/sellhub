import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';

class SearchRepository {
  final SellHubCatalogLocalStore _catalogStore;
  SearchRepository(Object? client, this._catalogStore);

  Future<List<SearchProductRes>> searchProduct(String query, int siteId) async {
    return _catalogStore.searchProducts(query, siteId);
  }

  Future<List<ProductResCommon>> fetchSearchProductDetails(
    int siteId,
    int first,
    String search,
  ) async {
    final products = await _catalogStore.loadProducts(
      siteId: siteId,
      search: search,
    );
    return products.take(first).toList(growable: false);
  }
}
