import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/models/site_information.dart';
import 'package:sellhub/features/product/data/models/site_slider_res_model.dart';
import 'package:sellhub/features/product/data/models/top_brand_res.dart';

enum StorefrontStatus { initial, loading, success, failure }

class StorefrontState extends Equatable {
  const StorefrontState({
    this.status = StorefrontStatus.initial,
    this.siteDetails,
    this.products = const <ProductResCommon>[],
    this.siteSlider = const <SiteSliderRes>[],
    this.allCategory = const <CategoriesRes>[],
    this.flashSale = const <ProductResCommon>[],
    this.newArrival = const <ProductResCommon>[],
    this.topBrand = const <TopBrandRes>[],
    this.categoriesProduct = const <ProductResCommon>[],
    this.homeCategoryProducts = const <int, List<ProductResCommon>>{},
    this.isLoading = false,
    this.isFetchingMore = false,
    this.allCategoryLoading = false,
    this.homeCategoryLoading = false,
    this.error,
    this.popularOffset = 0,
    this.flashSaleOffset = 0,
    this.newArrivalOffset = 0,
    this.categoryOffset = 0,
    this.hasMorePopular = true,
    this.hasMoreFlashSale = true,
    this.hasMoreNewArrival = true,
    this.hasMoreCategoryProduct = true,
    this.categoryIndex = 0,
    this.degradedSections = const <String>[],
  });

  final StorefrontStatus status;
  final SiteInformationRes? siteDetails;
  final List<ProductResCommon> products;
  final List<SiteSliderRes> siteSlider;
  final List<CategoriesRes> allCategory;
  final List<ProductResCommon> flashSale;
  final List<ProductResCommon> newArrival;
  final List<TopBrandRes> topBrand;
  final List<ProductResCommon> categoriesProduct;
  final Map<int, List<ProductResCommon>> homeCategoryProducts;
  final bool isLoading;
  final bool isFetchingMore;
  final bool allCategoryLoading;
  final bool homeCategoryLoading;
  final AppFailure? error;
  final int popularOffset;
  final int flashSaleOffset;
  final int newArrivalOffset;
  final int categoryOffset;
  final bool hasMorePopular;
  final bool hasMoreFlashSale;
  final bool hasMoreNewArrival;
  final bool hasMoreCategoryProduct;
  final int categoryIndex;
  final List<String> degradedSections;

  StorefrontState copyWith({
    StorefrontStatus? status,
    SiteInformationRes? siteDetails,
    List<ProductResCommon>? products,
    List<SiteSliderRes>? siteSlider,
    List<CategoriesRes>? allCategory,
    List<ProductResCommon>? flashSale,
    List<ProductResCommon>? newArrival,
    List<TopBrandRes>? topBrand,
    List<ProductResCommon>? categoriesProduct,
    Map<int, List<ProductResCommon>>? homeCategoryProducts,
    bool? isLoading,
    bool? isFetchingMore,
    bool? allCategoryLoading,
    bool? homeCategoryLoading,
    AppFailure? error,
    int? popularOffset,
    int? flashSaleOffset,
    int? newArrivalOffset,
    int? categoryOffset,
    bool? hasMorePopular,
    bool? hasMoreFlashSale,
    bool? hasMoreNewArrival,
    bool? hasMoreCategoryProduct,
    int? categoryIndex,
    List<String>? degradedSections,
    bool clearError = false,
  }) {
    return StorefrontState(
      status: status ?? this.status,
      siteDetails: siteDetails ?? this.siteDetails,
      products: products ?? this.products,
      siteSlider: siteSlider ?? this.siteSlider,
      allCategory: allCategory ?? this.allCategory,
      flashSale: flashSale ?? this.flashSale,
      newArrival: newArrival ?? this.newArrival,
      topBrand: topBrand ?? this.topBrand,
      categoriesProduct: categoriesProduct ?? this.categoriesProduct,
      homeCategoryProducts: homeCategoryProducts ?? this.homeCategoryProducts,
      isLoading: isLoading ?? this.isLoading,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      allCategoryLoading: allCategoryLoading ?? this.allCategoryLoading,
      homeCategoryLoading: homeCategoryLoading ?? this.homeCategoryLoading,
      error: clearError ? null : error ?? this.error,
      popularOffset: popularOffset ?? this.popularOffset,
      flashSaleOffset: flashSaleOffset ?? this.flashSaleOffset,
      newArrivalOffset: newArrivalOffset ?? this.newArrivalOffset,
      categoryOffset: categoryOffset ?? this.categoryOffset,
      hasMorePopular: hasMorePopular ?? this.hasMorePopular,
      hasMoreFlashSale: hasMoreFlashSale ?? this.hasMoreFlashSale,
      hasMoreNewArrival: hasMoreNewArrival ?? this.hasMoreNewArrival,
      hasMoreCategoryProduct:
          hasMoreCategoryProduct ?? this.hasMoreCategoryProduct,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      degradedSections: degradedSections ?? this.degradedSections,
    );
  }

  @override
  List<Object?> get props => [
    status,
    siteDetails,
    products,
    siteSlider,
    allCategory,
    flashSale,
    newArrival,
    topBrand,
    categoriesProduct,
    homeCategoryProducts,
    isLoading,
    isFetchingMore,
    allCategoryLoading,
    homeCategoryLoading,
    error,
    popularOffset,
    flashSaleOffset,
    newArrivalOffset,
    categoryOffset,
    hasMorePopular,
    hasMoreFlashSale,
    hasMoreNewArrival,
    hasMoreCategoryProduct,
    categoryIndex,
    degradedSections,
  ];
}
