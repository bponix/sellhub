import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sellhub/core/api/graphql_client_factory.dart';
import 'package:sellhub/core/api/local_graphql_api.dart';
import 'package:sellhub/core/api/local_seed_guard.dart';
import 'package:sellhub/core/local_seed/sellhub_catalog_seed.dart';
import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/categories/data/model/sub_sub_category_res.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_details.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';

class SellHubCatalogLocalStore {
  SellHubCatalogLocalStore({required LocalGraphQLApi api})
    : _client = createGraphQLClient(
        endpoint: 'https://example.invalid/graphql',
        link: LocalGraphQLLink(api: api),
      );

  final GraphQLClient _client;
  Future<void>? _seedFuture;

  static const String _seedKey = 'sellhub_catalog_seed';
  static const String _suppliersCollection = 'catalog_suppliers';
  static const String _categoriesCollection = 'catalog_categories';
  static const String _subCategoriesCollection = 'catalog_sub_categories';
  static const String _brandsCollection = 'catalog_brands';
  static const String _slidersCollection = 'catalog_sliders';
  static const String _siteInfoCollection = 'catalog_site_info';
  static const String _productsCollection = 'catalog_products';
  static const String _productDetailsCollection = 'catalog_product_details';
  static const int _marketplaceSiteId = 0;
  static const String _marketplaceDomain = 'reseller.store.bponi.com';
  static const String _seedRevision = 'v4';

  static final String _seedVersion =
      'catalog_${_seedRevision}_${SellHubCatalogSeed.suppliers.length}_${SellHubCatalogSeed.products.length}';

  static final _listCollectionDocument = gql(r'''
    query ListCollection($collection: String!) {
      listCollection(collection: $collection) {
        id
        payload
      }
    }
  ''');

  static final _replaceCollectionDocument = gql(r'''
    mutation ReplaceCollection(
      $collection: String!
      $entities: [LocalEntityInput!]!
    ) {
      replaceCollection(collection: $collection, entities: $entities) {
        count
      }
    }
  ''');

  Future<void> ensureSeeded() {
    final existing = _seedFuture;
    if (existing != null) {
      return existing;
    }
    final future = _ensureSeededInternal().whenComplete(() {
      _seedFuture = null;
    });
    _seedFuture = future;
    return future;
  }

  Future<List<StoreSummary>> loadSuppliers() async {
    await ensureSeeded();
    return _loadCollection<StoreSummary>(
      collection: _suppliersCollection,
      fromJson: StoreSummary.fromJson,
    );
  }

  Future<StoreSummary?> resolveSupplierByDomain(String domain) async {
    final suppliers = await loadSuppliers();
    for (final supplier in suppliers) {
      if (supplier.domain.trim().toLowerCase() == domain.trim().toLowerCase()) {
        return supplier;
      }
    }
    return null;
  }

  Future<List<CategoriesRes>> loadCategories(int siteId) async {
    final categories = await _loadCollection<CategoriesRes>(
      collection: _categoriesCollection,
      fromJson: CategoriesRes.fromJson,
    );
    if (siteId <= 0) {
      return _dedupeCategories(categories);
    }
    return categories
        .where((item) => item.siteId == siteId)
        .toList(growable: false);
  }

  Future<List<SubCategoryRes>> loadSubCategories(int siteId) async {
    final items = await _loadCollection<SubCategoryRes>(
      collection: _subCategoriesCollection,
      fromJson: SubCategoryRes.fromJson,
    );
    if (siteId <= 0) {
      final categories = await _loadCollection<CategoriesRes>(
        collection: _categoriesCollection,
        fromJson: CategoriesRes.fromJson,
      );
      return _dedupeSubCategories(items, categories);
    }
    return items.where((item) => item.siteId == siteId).toList(growable: false);
  }

  Future<List<SubSubCategoryRes>> loadSubSubCategories(int siteId) async {
    await ensureSeeded();
    return const <SubSubCategoryRes>[];
  }

  Future<List<TopBrandRes>> loadBrands(int siteId) async {
    final items = await _loadCollection<TopBrandRes>(
      collection: _brandsCollection,
      fromJson: TopBrandRes.fromJson,
    );
    if (siteId <= 0) return items;
    return items.where((item) => item.siteId == siteId).toList(growable: false);
  }

  Future<List<SiteSliderRes>> loadSliders(int siteId) async {
    final items = await _loadCollection<SiteSliderRes>(
      collection: _slidersCollection,
      fromJson: SiteSliderRes.fromJson,
    );
    if (siteId <= 0) return items;
    return items.where((item) => item.siteId == siteId).toList(growable: false);
  }

  Future<SiteInformationRes?> loadSiteInfo(String domain) async {
    final normalizedDomain = domain.trim().toLowerCase();
    if (normalizedDomain.isEmpty ||
        normalizedDomain == _marketplaceDomain ||
        normalizedDomain == 'www.$_marketplaceDomain' ||
        normalizedDomain == 'sellhub') {
      return _marketplaceSiteInfo();
    }
    final items = await _loadCollection<SiteInformationRes>(
      collection: _siteInfoCollection,
      fromJson: SiteInformationRes.fromJson,
    );
    for (final item in items) {
      if (item.domain?.trim().toLowerCase() == normalizedDomain) {
        return item;
      }
    }
    return null;
  }

  Future<List<ProductResCommon>> loadProducts({
    required int siteId,
    int? categoryId,
    int? subCategoryId,
    int? brandId,
    String? search,
    bool? isFlash,
    bool? isNew,
  }) async {
    final items = await _loadCollection<ProductResCommon>(
      collection: _productsCollection,
      fromJson: ProductResCommon.fromJson,
    );
    final categories = (categoryId != null || subCategoryId != null)
        ? await _loadCollection<CategoriesRes>(
            collection: _categoriesCollection,
            fromJson: CategoriesRes.fromJson,
          )
        : const <CategoriesRes>[];
    final subCategories = subCategoryId != null
        ? await _loadCollection<SubCategoryRes>(
            collection: _subCategoriesCollection,
            fromJson: SubCategoryRes.fromJson,
          )
        : const <SubCategoryRes>[];
    final brands = brandId != null
        ? await _loadCollection<TopBrandRes>(
            collection: _brandsCollection,
            fromJson: TopBrandRes.fromJson,
          )
        : const <TopBrandRes>[];
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final requestedCategoryTitle = categoryId == null
        ? null
        : _categoryTitleForId(categories, categoryId);
    final requestedSubCategoryTitle = subCategoryId == null
        ? null
        : _subCategoryTitleForId(subCategories, subCategoryId);
    final requestedBrandTitle = brandId == null
        ? null
        : _brandTitleForId(brands, brandId);
    return items
        .where((item) {
          if (siteId > 0 && item.siteId != siteId) return false;
          if (isFlash == true && item.isFlash != true) return false;
          if (isNew == true && !SellHubCatalogSeed.isNewProduct(item)) {
            return false;
          }
          if (normalizedSearch.isNotEmpty &&
              ![
                item.title ?? '',
                item.translation ?? '',
                ...item.brands,
                ...item.features.map(
                  (feature) => '${feature.key} ${feature.value}',
                ),
              ].join(' ').toLowerCase().contains(normalizedSearch)) {
            return false;
          }
          if (categoryId != null) {
            if (!_matchesCategory(
              item,
              categoryId,
              requestedCategoryTitle: requestedCategoryTitle,
            )) {
              return false;
            }
          }
          if (subCategoryId != null) {
            if (!_matchesSubCategory(
              item,
              subCategoryId,
              requestedSubCategoryTitle: requestedSubCategoryTitle,
            )) {
              return false;
            }
          }
          if (brandId != null) {
            if (!_matchesBrand(
              item,
              brandId,
              requestedBrandTitle: requestedBrandTitle,
            )) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<ProductDetailsRes?> loadProductDetails(String hid) async {
    final items = await _listRawCollection(_productDetailsCollection);
    final match = items.firstWhere(
      (item) => item['id'] == hid,
      orElse: () => const <String, dynamic>{},
    );
    if (match.isEmpty) return null;
    return ProductDetailsRes.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(match['payload'] as String? ?? '{}') as Map,
      ),
    );
  }

  Future<ProductResCommon?> loadProductById(int id) async {
    final items = await _loadCollection<ProductResCommon>(
      collection: _productsCollection,
      fromJson: ProductResCommon.fromJson,
    );
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<List<SearchProductRes>> searchProducts(
    String query,
    int siteId,
  ) async {
    final items = await loadProducts(siteId: siteId, search: query);
    return items
        .map(
          (item) => SearchProductRes(
            id: item.id ?? 0,
            title: item.title ?? '',
            thumbnail: item.thumbnail ?? '',
            price: item.price ?? 0,
            comparePrice: item.comparePrice ?? 0,
            wholesalePrice: item.wholesalePrice ?? item.price ?? 0,
            minResellPrice: item.minResellPrice ?? item.price ?? 0,
            maxResellPrice:
                item.maxResellPrice ?? item.comparePrice ?? item.price ?? 0,
            siteId: item.siteId ?? siteId,
            sku: item.sku ?? '',
          ),
        )
        .toList(growable: false);
  }

  SiteInformationRes _marketplaceSiteInfo() {
    return SiteInformationRes(
      address: 'Bangladesh',
      coverImage: null,
      createdAt: DateTime(2026, 4, 1),
      createdById: 1,
      currency: 'BDT',
      desktopLogo: null,
      desktopTheme: null,
      domain: _marketplaceDomain,
      email: 'hello@sellhub.local',
      favicon: null,
      foot: 'Sell any supplier product without inventory.',
      hostname: _marketplaceDomain,
      id: _marketplaceSiteId,
      industry: 'marketplace',
      latitude: 23.8103,
      locale: 'bn_BD',
      longitude: 90.4125,
      notice: 'Trusted supplier products in one reseller catalog.',
      phone: 8801700000000,
      phoneLogo: null,
      social: Social(
        facebook: null,
        instagram: null,
        twitter: null,
        youtube: null,
      ),
      street: 'Dhaka',
      title: 'SellHub',
      subscription: null,
      subscriptionFee: 0,
      theme: null,
      version: 1,
      whiteLabel: null,
      whiteLabelUrl: null,
      withdraw: 0,
      createdBy: CreatedBy(
        address: 'Dhaka',
        avatar: null,
        country: 50,
        currency: 'BDT',
        email: 'hello@sellhub.local',
        firstName: 'SellHub',
        id: 1,
        isStaff: false,
        name: 'SellHub',
        phone: 8801700000000,
        username: 'sellhub',
      ),
    );
  }

  Future<void> _ensureSeededInternal() async {
    final version = await loadLocalSeedVersion(_client, seedKey: _seedKey);
    if (version == _seedVersion && await _hasSeedData()) {
      return;
    }
    await _replaceCollection(
      collection: _suppliersCollection,
      items: SellHubCatalogSeed.suppliers,
      toJson: (item) => item,
      idOf: (item) => item['id'].toString(),
    );
    await _replaceCollection(
      collection: _categoriesCollection,
      items: SellHubCatalogSeed.categories,
      toJson: (item) => item.toJson(),
      idOf: (item) => '${item.siteId}-${item.id}',
    );
    await _replaceCollection(
      collection: _subCategoriesCollection,
      items: SellHubCatalogSeed.subCategories,
      toJson: (item) => item.toJson(),
      idOf: (item) => '${item.siteId}-${item.id}',
    );
    await _replaceCollection(
      collection: _brandsCollection,
      items: SellHubCatalogSeed.brands,
      toJson: (item) => item.toJson(),
      idOf: (item) => '${item.siteId}-${item.id}',
    );
    await _replaceCollection(
      collection: _slidersCollection,
      items: SellHubCatalogSeed.sliders,
      toJson: (item) => item.toJson(),
      idOf: (item) => '${item.siteId}-${item.id}',
    );
    await _replaceCollection(
      collection: _siteInfoCollection,
      items: SellHubCatalogSeed.siteInfo,
      toJson: (item) => item.toJson(),
      idOf: (item) => item.domain ?? '',
    );
    await _replaceCollection(
      collection: _productsCollection,
      items: SellHubCatalogSeed.products,
      toJson: (item) => item.toJson(),
      idOf: (item) => item.hid ?? '${item.siteId}-${item.id}',
    );
    await _replaceCollection(
      collection: _productDetailsCollection,
      items: SellHubCatalogSeed.productDetailsByHid.entries.toList(),
      toJson: (item) => item.value.toJson(),
      idOf: (item) => item.key,
    );
    await saveLocalSeedVersion(
      _client,
      seedKey: _seedKey,
      version: _seedVersion,
    );
  }

  Future<bool> _hasSeedData() async {
    final categories = await _queryRawCollection(_categoriesCollection);
    final subCategories = await _queryRawCollection(_subCategoriesCollection);
    final brands = await _queryRawCollection(_brandsCollection);
    final sliders = await _queryRawCollection(_slidersCollection);
    final siteInfo = await _queryRawCollection(_siteInfoCollection);
    final products = await _queryRawCollection(_productsCollection);
    final productDetails = await _queryRawCollection(_productDetailsCollection);
    return categories.length >= 40 &&
        subCategories.length >= 120 &&
        brands.length >= 30 &&
        sliders.length >= 20 &&
        siteInfo.length >= 10 &&
        products.length >= 1000 &&
        productDetails.length >= 1000;
  }

  Future<List<T>> _loadCollection<T>({
    required String collection,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final rawItems = await _listRawCollection(collection);
    return rawItems
        .map(
          (item) => fromJson(
            Map<String, dynamic>.from(
              jsonDecode(item['payload'] as String? ?? '{}') as Map,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _listRawCollection(
    String collection,
  ) async {
    await ensureSeeded();
    return _queryRawCollection(collection);
  }

  Future<List<Map<String, dynamic>>> _queryRawCollection(
    String collection,
  ) async {
    final result = await _client.query(
      QueryOptions(
        document: _listCollectionDocument,
        variables: <String, dynamic>{'collection': collection},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) {
      throw result.exception!;
    }
    return (result.data?['listCollection'] as List<dynamic>? ??
            const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<void> _replaceCollection<T>({
    required String collection,
    required List<T> items,
    required Map<String, dynamic> Function(T item) toJson,
    required String Function(T item) idOf,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: _replaceCollectionDocument,
        variables: <String, dynamic>{
          'collection': collection,
          ...encodeLocalEntityList<T>(
            items: items,
            toJson: toJson,
            idOf: idOf,
            updatedAtOf: (_) => DateTime.now().toIso8601String(),
          ),
        },
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) {
      throw result.exception!;
    }
  }

  List<CategoriesRes> _dedupeCategories(List<CategoriesRes> categories) {
    final grouped = <String, CategoriesRes>{};
    final totals = <String, int>{};
    for (final item in categories) {
      final key = _normalizedLabel(item.translation ?? item.title);
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => item);
      totals[key] = (totals[key] ?? 0) + (item.total ?? 0);
    }
    return grouped.entries
        .map((entry) {
          final source = entry.value;
          return CategoriesRes.fromJson({
            ...source.toJson(),
            'siteId': _marketplaceSiteId,
            'total': totals[entry.key] ?? source.total,
          });
        })
        .toList(growable: false);
  }

  List<SubCategoryRes> _dedupeSubCategories(
    List<SubCategoryRes> subCategories,
    List<CategoriesRes> categories,
  ) {
    final categoryTitleById = <int, String>{
      for (final item in categories)
        if (item.id != null)
          item.id!: (item.translation ?? item.title ?? '').trim(),
    };
    final marketplaceCategories = _dedupeCategories(categories);
    final marketplaceCategoryIdByTitle = <String, int>{
      for (final item in marketplaceCategories)
        if (item.id != null)
          _normalizedLabel(item.translation ?? item.title): item.id!,
    };
    final grouped = <String, SubCategoryRes>{};
    for (final item in subCategories) {
      final categoryTitle = categoryTitleById[item.categoryId ?? -1] ?? '';
      final key =
          '${_normalizedLabel(categoryTitle)}::${_normalizedLabel(item.translation ?? item.title)}';
      if (key == '::') continue;
      grouped.putIfAbsent(key, () => item);
    }
    return grouped.entries
        .map((entry) {
          final source = entry.value;
          final categoryTitle =
              categoryTitleById[source.categoryId ?? -1] ?? '';
          return SubCategoryRes.fromJson({
            ...source.toJson(),
            'siteId': _marketplaceSiteId,
            'categoryId':
                marketplaceCategoryIdByTitle[_normalizedLabel(categoryTitle)] ??
                source.categoryId,
          });
        })
        .toList(growable: false);
  }

  String? _categoryTitleForId(List<CategoriesRes> categories, int categoryId) {
    for (final item in categories) {
      if (item.id == categoryId) {
        return item.translation ?? item.title;
      }
    }
    return null;
  }

  String? _subCategoryTitleForId(
    List<SubCategoryRes> subCategories,
    int subCategoryId,
  ) {
    for (final item in subCategories) {
      if (item.id == subCategoryId) {
        return item.translation ?? item.title;
      }
    }
    return null;
  }

  String? _brandTitleForId(List<TopBrandRes> brands, int brandId) {
    for (final item in brands) {
      if (item.id == brandId) {
        return item.translation ?? item.title;
      }
    }
    return null;
  }

  bool _matchesCategory(
    ProductResCommon item,
    int categoryId, {
    String? requestedCategoryTitle,
  }) {
    final exact = SellHubCatalogSeed.categoryIdForProduct(item);
    if (exact == categoryId) return true;
    if (requestedCategoryTitle == null) return false;
    return _normalizedLabel(_featureValue(item, 'Category')) ==
        _normalizedLabel(requestedCategoryTitle);
  }

  bool _matchesSubCategory(
    ProductResCommon item,
    int subCategoryId, {
    String? requestedSubCategoryTitle,
  }) {
    final exact = SellHubCatalogSeed.subCategoryIdForProduct(item);
    if (exact == subCategoryId) return true;
    if (requestedSubCategoryTitle == null) return false;
    return _normalizedLabel(
          _featureValue(item, 'Subcategory') ??
              _featureValue(item, 'SubCategory'),
        ) ==
        _normalizedLabel(requestedSubCategoryTitle);
  }

  bool _matchesBrand(
    ProductResCommon item,
    int brandId, {
    String? requestedBrandTitle,
  }) {
    if (requestedBrandTitle == null) return false;
    return item.brands.any(
      (brand) =>
          _normalizedLabel(brand) == _normalizedLabel(requestedBrandTitle),
    );
  }

  String _normalizedLabel(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String? _featureValue(ProductResCommon product, String key) {
    for (final feature in product.features) {
      if (feature.key == key) {
        return feature.value;
      }
    }
    return null;
  }
}
