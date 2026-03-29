import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/categories/data/model/sub_sub_category_res.dart';
import 'package:sellhub/features/categories/query/fetch_categories_all_data.dart';
import 'package:sellhub/features/categories/query/sub_category_query.dart';
import 'package:sellhub/features/categories/query/sub_sub_category_query.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

import '../../product/data/models/category_res.dart';
import '../../product/query/categories.dart';

class CategoryRepository {
  final GraphQLClient _client;
  CategoryRepository(this._client);

  Future<List<CategoriesRes>> fetchCategories(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORIES),
        variables: {
          "siteId": [siteId],
          "childId": null,
          "first": 2048,
        },
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data != null &&
        result.data?['storeCategories']['edges'] != null) {
      final List edges = result.data?['storeCategories']['edges'];
      return edges.map((e) => CategoriesRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  // sub category
  Future<List<SubCategoryRes>> fetchSubCategories(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSUBCATEGORIES),
        variables: {
          "siteId": [siteId],
          "childId": null,
          "first": 2048,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    // print('Fetch Sub Categories not data >>>>>>>');
    // print(result.data);

    if (result.data != null &&
        result.data?['storeSubCategories']['edges'] != null) {
      final List edges = result.data?['storeSubCategories']['edges'];
      return edges.map((e) => SubCategoryRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
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
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSUBCATEGORIESDATA),
        variables: {
          "siteId": [siteId],
          "categoryId": null,
          "subCategoryId": subCategoryId,
          "subSubCategoryId": null,
          "brandId": brandId,
          "collectionId": null,
          "campaignId": null,
          "shopId": null,
          "isFlash": null,
          "isNew": null,
          "childId": null,
          "percentage": null,
          "isReseller": false,
          "isBasePrice": false,
          "queryType": queryType, // this is need for filtering
          "search": null,
          "first": first,
          "offset": offset,
          "minPrice": null,
          "maxPrice": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    // print('Fetch Sub Categories Data>>>>>>>');
    // print(result.data);

    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
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
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORIESALLDATA),
        variables: {
          "siteId": [siteId],
          "categoryId": categoryId,
          "subCategoryId": null,
          "subSubCategoryId": null,
          "brandId": brandId,
          "tagIds": null,
          "collectionId": null,
          "campaignId": null,
          "shopId": null,
          "isFlash": null,
          "isNew": null,
          "childId": null,
          "percentage": null,
          "isReseller": false,
          "isBasePrice": false,
          "queryType": queryType,
          "search": null,
          "first": first,
          "offset": offset,
          "minPrice": null,
          "maxPrice": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    // print('Fetch Sub Categories Data>>>>>>>');
    // print(result.data);

    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  // sub sub category
  Future<List<SubSubCategoryRes>> fetchSubSubCategories(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSUBSUBCATEGORY),
        variables: {
          "siteId": [siteId],
          "childId": null,
          "first": 2048,
        },
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data != null &&
        result.data?['storeSubSubCategories']['edges'] != null) {
      final List edges = result.data?['storeSubSubCategories']['edges'];
      return edges.map((e) => SubSubCategoryRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }
}
