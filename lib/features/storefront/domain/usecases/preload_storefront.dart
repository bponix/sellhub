import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/storefront/domain/repositories/storefront_repository.dart';

class StorefrontBootstrapData {
  const StorefrontBootstrapData({
    required this.site,
    required this.products,
    required this.categories,
    required this.siteSliders,
    required this.flashSale,
    required this.newArrival,
    required this.topBrand,
    this.degradedSections = const <String>[],
  });

  final SiteInformationRes? site;
  final List<ProductResCommon> products;
  final List<CategoriesRes> categories;
  final List<SiteSliderRes> siteSliders;
  final List<ProductResCommon> flashSale;
  final List<ProductResCommon> newArrival;
  final List<TopBrandRes> topBrand;
  final List<String> degradedSections;
}

class PreloadStorefront {
  const PreloadStorefront(this._repository);

  final StorefrontRepository _repository;

  Future<StorefrontBootstrapData> call({
    required String domain,
    required int siteId,
    required int first,
  }) async {
    final site = await _repository.fetchSiteInformation(domain);
    if (site?.id == null) {
      throw Exception('Storefront was not resolved for domain $domain.');
    }

    final degradedSections = <String>[];

    Future<T> guard<T>(
      String key,
      Future<T> Function() loader,
      T fallback,
    ) async {
      try {
        return await loader();
      } catch (_) {
        degradedSections.add(key);
        return fallback;
      }
    }

    final results = await Future.wait<Object?>([
      guard<List<ProductResCommon>>(
        'products',
        () => _repository.fetchProducts(siteId, first, 0),
        const <ProductResCommon>[],
      ),
      guard<List<CategoriesRes>>(
        'categories',
        () => _repository.fetchCategories(siteId),
        const <CategoriesRes>[],
      ),
      guard<List<SiteSliderRes>>(
        'sliders',
        () => _repository.fetchSiteSlider(siteId),
        const <SiteSliderRes>[],
      ),
      guard<List<ProductResCommon>>(
        'flash_sale',
        () => _repository.fetchFlashSale(siteId, first, 0),
        const <ProductResCommon>[],
      ),
      guard<List<ProductResCommon>>(
        'new_arrival',
        () => _repository.fetchNewArrival(siteId, first, 0),
        const <ProductResCommon>[],
      ),
      guard<List<TopBrandRes>>(
        'top_brand',
        () => _repository.fetchTopBrand(siteId),
        const <TopBrandRes>[],
      ),
    ]);

    return StorefrontBootstrapData(
      site: site,
      products: results[0] as List<ProductResCommon>,
      categories: results[1] as List<CategoriesRes>,
      siteSliders: results[2] as List<SiteSliderRes>,
      flashSale: results[3] as List<ProductResCommon>,
      newArrival: results[4] as List<ProductResCommon>,
      topBrand: results[5] as List<TopBrandRes>,
      degradedSections: degradedSections,
    );
  }
}
