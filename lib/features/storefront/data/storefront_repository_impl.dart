import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/storefront/domain/repositories/storefront_repository.dart';

class StorefrontRepositoryImpl implements StorefrontRepository {
  StorefrontRepositoryImpl(this._repository);

  final ProductRepository _repository;

  @override
  Future<List<CategoriesRes>> fetchCategories(int siteId) {
    return _repository.fetchCategories(siteId);
  }

  @override
  Future<List<ProductResCommon>> fetchCategoryProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
  ) {
    return _repository.fetchCategoryProduct(siteId, categoryId, first, offset);
  }

  @override
  Future<List<ProductResCommon>> fetchFlashSale(
    int siteId,
    int first,
    int offset,
  ) {
    return _repository.fetchFlashSale(siteId, first, offset);
  }

  @override
  Future<List<ProductResCommon>> fetchNewArrival(
    int siteId,
    int first,
    int offset,
  ) {
    return _repository.fetchNewArrival(siteId, first, offset);
  }

  @override
  Future<List<ProductResCommon>> fetchProducts(
    int siteId,
    int first,
    int offset,
  ) {
    return _repository.fetchProducts(siteId, first, offset);
  }

  @override
  Future<SiteInformationRes?> fetchSiteInformation(String domain) async {
    return _repository.fetchSiteInformation(domain);
  }

  @override
  Future<List<SiteSliderRes>> fetchSiteSlider(int siteId) {
    return _repository.fetchSiteSlider(siteId);
  }

  @override
  Future<List<TopBrandRes>> fetchTopBrand(int siteId) {
    return _repository.fetchTopBrand(siteId);
  }
}
