import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';

abstract class StorefrontRepository {
  Future<SiteInformationRes?> fetchSiteInformation(String domain);
  Future<List<ProductResCommon>> fetchProducts(
    int siteId,
    int first,
    int offset,
  );
  Future<List<SiteSliderRes>> fetchSiteSlider(int siteId);
  Future<List<CategoriesRes>> fetchCategories(int siteId);
  Future<List<ProductResCommon>> fetchFlashSale(
    int siteId,
    int first,
    int offset,
  );
  Future<List<ProductResCommon>> fetchNewArrival(
    int siteId,
    int first,
    int offset,
  );
  Future<List<TopBrandRes>> fetchTopBrand(int siteId);
  Future<List<ProductResCommon>> fetchCategoryProduct(
    int siteId,
    int categoryId,
    int first,
    int offset,
  );
}
