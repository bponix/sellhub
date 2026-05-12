import 'package:sellhub/core/local_seed/sellhub_catalog_local_store.dart';
import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'package:sellhub/core/supplier_trust/supplier_trust.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_res.dart';
import 'package:sellhub/features/product/data/models/customer_review_req.dart';
import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';

class ProductRepository {
  final SupplierTrustLocalStore _trustStore;
  final SellHubCatalogLocalStore _catalogStore;
  final SellHubCommerceLocalStore _commerceStore;

  ProductRepository(
    Object? client,
    this._trustStore,
    this._catalogStore,
    this._commerceStore,
  );

  Future<List<ProductResCommon>> fetchProducts(
    int siteId,
    int first,
    int offset,
  ) async {
    final products = await _catalogStore.loadProducts(siteId: siteId);
    return products.skip(offset).take(first).toList(growable: false);
  }

  Future<bool> makeCustomerReview(SubmitReviewReq model) async {
    return _commerceStore.makeCustomerReview(model);
  }

  Future<List<CustomerReviewResModel>> FetchCustomerReview(
    int productId,
    int first,
  ) async {
    return _commerceStore.fetchCustomerReviews(productId, first);
  }

  Future<List<ProductResCommon>> fetchRelatedProducts(
    int siteId,
    int? categoryId,
    int? subCategoryId,
    int first,
    int offset,
  ) async {
    final products = await _catalogStore.loadProducts(
      siteId: siteId,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
    return products.skip(offset).take(first).toList(growable: false);
  }

  Future<List<SiteSliderRes>> fetchSiteSlider(int siteId) async {
    return _catalogStore.loadSliders(siteId);
  }

  Future<List<CategoriesRes>> fetchCategories(int siteId) async {
    return _catalogStore.loadCategories(siteId);
  }

  Future<ProductDetailsRes?>? fetchProductDetails(String hid) async {
    return _catalogStore.loadProductDetails(hid);
  }

  Future<SupplierTrustProfile?> fetchSupplierTrustSummary(
    int siteId, {
    String domain = '',
    String title = '',
  }) async {
    return _trustStore.loadProfile(siteId: siteId, domain: domain, title: title);
  }

  Future<ProductResCommon?> fetchProductById(int id) async {
    return _catalogStore.loadProductById(id);
  }

  Future<SiteInformationRes?>? fetchSiteInformation(String domain) async {
    return _catalogStore.loadSiteInfo(domain);
  }

  Future<List<ProductResCommon>> fetchFlashSale(
    int siteId,
    int first,
    int offset,
  ) async {
    final products = await _catalogStore.loadProducts(siteId: siteId, isFlash: true);
    return products.skip(offset).take(first).toList(growable: false);
  }

  Future<List<ProductResCommon>> fetchNewArrival(
    int siteId,
    int first,
    int offset,
  ) async {
    final products = await _catalogStore.loadProducts(siteId: siteId, isNew: true);
    return products.skip(offset).take(first).toList(growable: false);
  }

  Future<List<TopBrandRes>> fetchTopBrand(int siteId) async {
    return _catalogStore.loadBrands(siteId);
  }

  Future<List<ProductResCommon>> fetchCategoryProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
  ) async {
    final products = await _catalogStore.loadProducts(
      siteId: siteId,
      categoryId: categoryId,
    );
    return products.skip(offset).take(first).toList(growable: false);
  }
}
