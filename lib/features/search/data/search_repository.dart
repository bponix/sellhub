import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';
import 'package:sellhub/features/search/query/fetchProductBySearch.dart';

class SearchRepository {
  final GraphQLClient _client;
  SearchRepository(this._client);

  Future<List<SearchProductRes>> searchProduct(String query, int siteId) async {
    final rows = await _search(query: query, siteId: siteId, first: 12);
    return rows
        .map((row) => SearchProductRes.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ProductResCommon>> fetchSearchProductDetails(
    int siteId,
    int first,
    String search,
  ) async {
    final rows = await _search(query: search, siteId: siteId, first: first);
    return rows.map(ProductResCommon.fromJson).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _search({
    required String query,
    required int siteId,
    required int first,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <Map<String, dynamic>>[];
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHPRODUCTDETAILSBYSEARCH),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'search': normalized,
          'isPrivate': false,
          'isReseller': true,
          'isBasePrice': true,
          'first': first,
          'offset': 0,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeProducts']?['edges'];
    if (edges is! List) return const <Map<String, dynamic>>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }
}
