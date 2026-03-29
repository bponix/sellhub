import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/product/mutation/customer_review_mutation.dart';
import 'package:sellhub/features/product/query/categories.dart';
import 'package:sellhub/features/product/query/flass_sale.dart';
import 'package:sellhub/features/product/query/kichen_appliance.dart';
import 'package:sellhub/features/product/query/new_arrival.dart';
import 'package:sellhub/features/product/query/product_details.dart';
import 'package:sellhub/features/product/query/related_product.dart';
import 'package:sellhub/features/product/query/site_information.dart';
import 'package:sellhub/features/product/query/site_slider.dart';
import 'package:sellhub/features/product/query/top_brand.dart';
import 'package:sellhub/features/profile/query/store_product_by_id.dart';

import '../query/fetchProduct.dart';

class ProductRepository {
  final GraphQLClient _client;

  ProductRepository(this._client);

  Future<List<ProductResCommon>> fetchProducts(
    int siteId,
    int first,
    int offset,
  ) async {
    //print('fetch products api call');
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITESQUERY),
        variables: {
          "siteId": [siteId],
          "first": first,
          "offset": offset,
          "queryType": "latest",
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      //print('has Exception product fetch');
      //print(result.exception);
      throw Exception(result.exception.toString());
    }
    //print(result.data);
    //log(result.data.toString());
    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  Future<bool> makeCustomerReview(SubmitReviewReq model) async {
    final QueryResult result = await _client.mutate(
      MutationOptions(
        document: gql(SUBMIT_REVIEW_MUTATION),
        variables: model.toJson(),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    if (result.data != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<List<CustomerReviewResModel>> FetchCustomerReview(
    int productId,
    int first,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCH_CUSTOMER_REVIEW),
        variables: {"productId": productId, "first": first, "after": null},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //  print(result.data);
    if (result.data != null &&
        result.data?['storeProductReviews']['edges'] != null) {
      final List edges = result.data?['storeProductReviews']['edges'];
      return edges
          .map((e) => CustomerReviewResModel.fromJson(e['node']))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<ProductResCommon>> fetchRelatedProducts(
    int siteId,
    int? categoryId,
    int? subCategoryId,
    int first,
    int offset,
  ) async {
    //  print('fetch related product api call');
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHRELATEDPRODUCT),
        variables: {
          "siteId": [siteId],
          "categoryId": categoryId,
          "subCategoryId": subCategoryId,
          "subSubCategoryId": null,
          "brandId": null,
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
      //  print('has Exception related');
      throw Exception(result.exception.toString());
    }
    //print(result.data);
    //log(result.data.toString());
    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  Future<List<SiteSliderRes>> fetchSiteSlider(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITESLIDER),
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

    if (result.data != null && result.data?['siteSliders']['edges'] != null) {
      final List edges = result.data?['siteSliders']['edges'];
      return edges.map((e) => SiteSliderRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

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

  Future<ProductDetailsRes?>? fetchProductDetails(String hid) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHPRODUCTDETAILS),
        variables: {
          "childId": null,
          "percentage": null,
          "isReseller": false,
          "isBasePrice": false,
          "hid": hid,
        },
        /*
            Change fetchPolicy from FetchPolicy.cacheFirst to FetchPolicy.networkOnly (or FetchPolicy.noCache).
networkOnly: Fetches from network, saves to cache. Good for keeping cache updated but always showing fresh data.
noCache: Fetches from network, does NOT save to cache. Good if we suspect cache corruption.
Decision: Use networkOnly so we get fresh data but normally populate the cache for other potential uses, unless the user specifically requested "no cache" behavior. Given the "images list contain another product images list" (merging issue), networkOnly ensures the UI gets what the server sends right now.
             */
        fetchPolicy: FetchPolicy
            .networkOnly, // this is very important (get fresh data from network)
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //log(result.data.toString());
    if (result.data != null) {
      final edges = result.data?['storeProductByHid'];
      return ProductDetailsRes.fromJson(edges);
    } else {
      return null;
    }
  }

  Future<ProductResCommon?> fetchProductById(int id) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCH_STORE_PRODUCT_BY_ID),
        variables: <String, dynamic>{'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?['storeProduct'];
    if (data is Map<String, dynamic>) {
      return ProductResCommon.fromJson(data);
    }
    if (data is Map) {
      return ProductResCommon.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<SiteInformationRes?>? fetchSiteInformation(String domain) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHSITEINFORMATION),
        variables: {"domain": domain},
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    //log(result.data.toString());
    if (result.data != null) {
      final edges = result.data?['site'];
      //print(edges);
      return SiteInformationRes.fromJson(Map<String, dynamic>.from(edges));
    } else {
      return null;
    }
  }

  Future<List<ProductResCommon>> fetchFlashSale(
    int siteId,
    int first,
    int offset,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHFLASHSALEQUERY),
        variables: {
          "siteId": [siteId],
          "categoryId": null,
          "subCategoryId": null,
          "subSubCategoryId": null,
          "brandId": null,
          "collectionId": null,
          "campaignId": null,
          "shopId": null,
          "isFlash": true,
          "isNew": null,
          "childId": null,
          "percentage": null,
          "isReseller": false,
          "isBasePrice": false,
          "queryType": "latest",
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

    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  Future<List<ProductResCommon>> fetchNewArrival(
    int siteId,
    int first,
    int offset,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHNEWARRIVAL),
        variables: {
          "siteId": [siteId],
          "isNew": true,
          "childId": null,
          "percentage": null,
          "isReseller": false,
          "queryType": "latest",
          "search": null,
          "first": first,
          "offset": offset,
          "after": null,
          "minPrice": null,
          "maxPrice": null,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  Future<List<TopBrandRes>> fetchTopBrand(int siteId) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHTOPBRAND),
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

    if (result.data != null && result.data?['storeBrands']['edges'] != null) {
      final List edges = result.data?['storeBrands']['edges'];
      return edges.map((e) => TopBrandRes.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }

  Future<List<ProductResCommon>> fetchCategoryProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
  ) async {
    final QueryResult result = await _client.query(
      QueryOptions(
        document: gql(FETCHCATEGORYPRODUCT),
        variables: {
          "siteId": [siteId],
          "categoryId": categoryId,
          "subCategoryId": null,
          "subSubCategoryId": null,
          "brandId": null,
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

    if (result.data != null && result.data?['storeProducts']['edges'] != null) {
      final List edges = result.data?['storeProducts']['edges'];
      return edges.map((e) => ProductResCommon.fromJson(e['node'])).toList();
    } else {
      return [];
    }
  }
}
