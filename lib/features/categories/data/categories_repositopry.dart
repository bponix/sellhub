import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';
import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/categories/data/model/sub_sub_category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

import '../../product/data/models/category_res.dart';

class CategoryRepository {
  final SellHubCatalogLocalStore _catalogStore;
  CategoryRepository(Object? client, this._catalogStore);

  Future<List<CategoriesRes>> fetchCategories(int siteId) async {
    return _catalogStore.loadCategories(siteId);
  }

  // sub category
  Future<List<SubCategoryRes>> fetchSubCategories(int siteId) async {
    return _catalogStore.loadSubCategories(siteId);
  }

  // fetch sub category data
  Future<List<ProductResCommon>> fetchSubCategoriesProducts(
    int siteId,
    int subCategoryId,
    int first,
    int offset,
    String queryType, {
    int? brandId,
  }) async {
    final products = await _catalogStore.loadProducts(
      siteId: siteId,
      subCategoryId: subCategoryId,
      brandId: brandId,
    );
    return products.skip(offset).take(first).toList(growable: false);
  }

  // fetch category all data (when user click see all)
  Future<List<ProductResCommon>> fetchCategoriesAllProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
    String queryType, {
    int? brandId,
  }) async {
    final products = await _catalogStore.loadProducts(
      siteId: siteId,
      categoryId: categoryId,
      brandId: brandId,
    );
    return products.skip(offset).take(first).toList(growable: false);
  }

  // sub sub category
  Future<List<SubSubCategoryRes>> fetchSubSubCategories(int siteId) async {
    return _catalogStore.loadSubSubCategories(siteId);
  }
}
