import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/categories/data/model/sub_sub_category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

import '../../product/data/models/category_res.dart';
import 'package:sellhub/features/product/query/categories.dart';
import 'package:sellhub/features/categories/query/sub_category_query.dart';
import 'package:sellhub/features/categories/query/sub_sub_category_query.dart';
import 'package:sellhub/features/categories/query/fetch_categories_all_data.dart';

class CategoryRepository {
  final GraphQLClient _client;
  CategoryRepository(this._client);

  Future<List<CategoriesRes>> fetchCategories(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORIES),
        variables: _categoryVariables(siteId),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _nodes(
      result,
      'storeCategories',
    ).map(CategoriesRes.fromJson).toList(growable: false);
  }

  // sub category
  Future<List<SubCategoryRes>> fetchSubCategories(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSUBCATEGORIES),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'categoryId': null,
          'isActive': true,
          'isPrivate': false,
          'first': 300,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _nodes(
      result,
      'storeSubCategories',
    ).map(SubCategoryRes.fromJson).toList(growable: false);
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
    return _fetchProducts(
      siteId: siteId,
      subCategoryId: subCategoryId,
      brandId: brandId,
      first: first,
      offset: offset,
      queryType: queryType,
    );
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
    return _fetchProducts(
      siteId: siteId,
      categoryId: categoryId,
      brandId: brandId,
      first: first,
      offset: offset,
      queryType: queryType,
    );
  }

  // sub sub category
  Future<List<SubSubCategoryRes>> fetchSubSubCategories(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSUBSUBCATEGORY),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'categoryId': null,
          'subCategoryId': null,
          'isActive': true,
          'isPrivate': false,
          'first': 300,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _nodes(
      result,
      'storeSubSubCategories',
    ).map(SubSubCategoryRes.fromJson).toList(growable: false);
  }

  Future<List<ProductResCommon>> _fetchProducts({
    required int siteId,
    required int first,
    required int offset,
    required String queryType,
    int? categoryId,
    int? subCategoryId,
    int? brandId,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORIESALLDATA),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'brandId': brandId,
          'categoryId': categoryId,
          'subCategoryId': subCategoryId,
          'isPrivate': false,
          'isReseller': true,
          'isBasePrice': true,
          'queryType': queryType,
          'first': first,
          'offset': offset,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _nodes(
      result,
      'storeProducts',
    ).map(ProductResCommon.fromJson).toList(growable: false);
  }

  static Map<String, dynamic> _categoryVariables(int siteId) =>
      <String, dynamic>{
        'siteId': <int>[siteId],
        'childId': null,
        'isActive': true,
        'isPrivate': false,
        'search': null,
        'first': 300,
        'after': null,
      };

  static List<Map<String, dynamic>> _nodes(
    QueryResult<Object?> result,
    String key,
  ) {
    if (result.hasException) throw result.exception!;
    final edges = result.data?[key]?['edges'];
    if (edges is! List) return const <Map<String, dynamic>>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((node) => Map<String, dynamic>.from(node))
        .toList(growable: false);
  }
}
