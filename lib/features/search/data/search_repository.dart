import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';

import '../query/fetchProductBySearch.dart';

class SearchRepository {
  final GraphQLClient _client;
  SearchRepository(this._client);

  Map<String, String> requestHeaders = {
    "Content-Type": "application/json",
    "Authorization": 'Bearer yA9mppsDdJbhHiNt101',
  };

  Future<List<SearchProductRes>> searchProduct(String query, int siteId) async {
    final url = Uri.parse(
      'https://search.bponi.com/indexes/store_product/search'
      '?q=$query&limit=20&filter=site_id%3D$siteId',
    );

    final response = await http.get(url, headers: requestHeaders);
    //print(response.statusCode);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // print('Data is>>>>>>>');
      // print(data);
      final List list = data['hits'];

      return list.map((e) => SearchProductRes.fromJson(e)).toList();
    } else {
      throw Exception('Search Failed');
    }
  }

  Future<List<ProductResCommon>> fetchSearchProductDetails(
    int siteId,
    int first,
    String search,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHPRODUCTDETAILSBYSEARCH),
        variables: {
          "siteId": [siteId],
          "categoryId": null,
          "subCategoryId": null,
          "subSubCategoryId": null,
          "brandId": null,
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
          "queryType": "latest",
          "search": search,
          "first": first,
          "offset": 0,
          "minPrice": null,
          "maxPrice": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    // print(result.data);
    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }
}
