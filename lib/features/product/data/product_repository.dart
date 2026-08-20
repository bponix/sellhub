import 'package:sellhub/core/supplier_trust/supplier_trust.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/sellhub_product_winner.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/product/mutation/customer_review_mutation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/product/query/fetchProduct.dart';
import 'package:sellhub/features/product/query/product_details.dart';
import 'package:sellhub/features/product/query/site_slider.dart';
import 'package:sellhub/features/product/query/categories.dart';
import 'package:sellhub/features/product/query/site_information.dart';
import 'package:sellhub/features/product/query/top_brand.dart';
import 'package:sellhub/features/profile/query/store_product_by_id.dart';

class ProductRepository {
  final SupplierTrustLocalStore _trustStore;
  final GraphQLClient _client;

  ProductRepository(this._client, this._trustStore);

  static final _sellHubProductWinnersDocument = gql(r'''
    query SellHubProductWinners($siteId: Int!, $userId: Int!, $limit: Int) {
      storeSellhubProductWinners(siteId: $siteId, userId: $userId, limit: $limit) {
        productId title slug thumbnail score tier badges reasons nextAction
        orderCount quoteCount reorderCount attributedOrderCount
        profitMarginPct localDemandScore supplierQualityScore supplierQualityTier
        payoutProofScore payoutProofTier
      }
    }
  ''');

  Future<List<SellHubProductWinner>> fetchSellHubProductWinners({
    required int siteId,
    required int userId,
    int limit = 8,
  }) async {
    if (siteId <= 0 || userId <= 0) return const <SellHubProductWinner>[];
    final result = await _client.query(
      QueryOptions(
        document: _sellHubProductWinnersDocument,
        variables: <String, dynamic>{
          'siteId': siteId,
          'userId': userId,
          'limit': limit.clamp(1, 20),
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final rows = result.data?['storeSellhubProductWinners'];
    if (rows is! List) return const <SellHubProductWinner>[];
    return rows
        .whereType<Map>()
        .map(
          (row) =>
              SellHubProductWinner.fromJson(Map<String, dynamic>.from(row)),
        )
        .where((winner) => winner.productId > 0)
        .toList(growable: false);
  }

  Future<List<ProductResCommon>> fetchProducts(
    int siteId,
    int first,
    int offset,
  ) async {
    return _fetchProducts(siteId: siteId, first: first, offset: offset);
  }

  Future<bool> makeCustomerReview(SubmitReviewReq model) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(SUBMIT_REVIEW_MUTATION),
        variables: <String, dynamic>{
          'userId': model.userId,
          'productId': model.productId,
          'description': model.description ?? '',
          'rating': model.rating ?? 5,
          'feedbackType': model.feedbackType ?? 'review',
          'status': model.status ?? 'active',
          'siteId': model.siteId,
          'image': model.image,
          'feedbacker': model.feedbacker,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    return result.data?['selfStoreProductReviewCreate'] != null;
  }

  Future<List<CustomerReviewResModel>> FetchCustomerReview(
    int productId,
    int first,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCH_CUSTOMER_REVIEW),
        variables: <String, dynamic>{
          'productId': productId,
          'first': first,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final edges = result.data?['storeProductReviews']?['edges'];
    if (edges is! List) return const <CustomerReviewResModel>[];
    return edges
        .whereType<Map>()
        .map((edge) => edge['node'])
        .whereType<Map>()
        .map(
          (row) =>
              CustomerReviewResModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<List<ProductResCommon>> fetchRelatedProducts(
    int siteId,
    int? categoryId,
    int? subCategoryId,
    int first,
    int offset,
  ) async {
    return _fetchProducts(
      siteId: siteId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      first: first,
      offset: offset,
    );
  }

  Future<List<SiteSliderRes>> fetchSiteSlider(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITESLIDER),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'childId': null,
          'isPrivate': false,
          'first': 50,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _connectionNodes(
      result,
      'siteSliders',
    ).map(SiteSliderRes.fromJson).toList(growable: false);
  }

  Future<List<CategoriesRes>> fetchCategories(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORIES),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'childId': null,
          'isActive': true,
          'isPrivate': false,
          'search': null,
          'first': 200,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _connectionNodes(
      result,
      'storeCategories',
    ).map(CategoriesRes.fromJson).toList(growable: false);
  }

  Future<ProductDetailsRes?>? fetchProductDetails(String hid) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHPRODUCTDETAILS),
        variables: <String, dynamic>{
          'hid': hid,
          'childId': null,
          'childType': null,
          'percentage': null,
          'isReseller': true,
          'isBasePrice': true,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['storeProductByHid'];
    return row is Map
        ? ProductDetailsRes.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<SupplierTrustProfile?> fetchSupplierTrustSummary(
    int siteId, {
    String domain = '',
    String title = '',
  }) async {
    return _trustStore.loadProfile(
      siteId: siteId,
      domain: domain,
      title: title,
    );
  }

  Future<ProductResCommon?> fetchProductById(int id) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCH_STORE_PRODUCT_BY_ID),
        variables: <String, dynamic>{'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['storeProduct'];
    return row is Map
        ? ProductResCommon.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<SiteInformationRes?>? fetchSiteInformation(String domain) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITEINFORMATION),
        variables: <String, dynamic>{'domain': domain},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['site'];
    return row is Map
        ? SiteInformationRes.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  Future<List<ProductResCommon>> fetchFlashSale(
    int siteId,
    int first,
    int offset,
  ) async {
    return _fetchProducts(
      siteId: siteId,
      first: first,
      offset: offset,
      isFlash: true,
    );
  }

  Future<List<ProductResCommon>> fetchNewArrival(
    int siteId,
    int first,
    int offset,
  ) async {
    return _fetchProducts(
      siteId: siteId,
      first: first,
      offset: offset,
      isNew: true,
    );
  }

  Future<List<TopBrandRes>> fetchTopBrand(int siteId) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHTOPBRAND),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'childId': null,
          'isActive': true,
          'isPrivate': false,
          'search': null,
          'first': 100,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _connectionNodes(
      result,
      'storeBrands',
    ).map(TopBrandRes.fromJson).toList(growable: false);
  }

  Future<List<ProductResCommon>> fetchCategoryProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
  ) async {
    return _fetchProducts(
      siteId: siteId,
      categoryId: categoryId,
      first: first,
      offset: offset,
    );
  }

  Future<List<ProductResCommon>> _fetchProducts({
    required int siteId,
    required int first,
    required int offset,
    int? categoryId,
    int? subCategoryId,
    bool? isFlash,
    bool? isNew,
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITESQUERY),
        variables: <String, dynamic>{
          'siteId': <int>[siteId],
          'categoryId': categoryId,
          'subCategoryId': subCategoryId,
          'isFlash': isFlash,
          'isNew': isNew,
          'isPrivate': false,
          'isReseller': true,
          'isBasePrice': true,
          'first': first,
          'offset': offset,
          'after': null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    return _connectionNodes(
      result,
      'storeProducts',
    ).map(ProductResCommon.fromJson).toList(growable: false);
  }

  static List<Map<String, dynamic>> _connectionNodes(
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
