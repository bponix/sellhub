import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/categories/data/model/sub_category_res.dart';
import 'package:sellhub/features/categories/data/model/sub_sub_category_res.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class CategoriesState extends Equatable {
  const CategoriesState({
    this.queryType = 'latest',
    this.siteId,
    this.allCategory = const <CategoriesRes>[],
    this.subCategory = const <SubCategoryRes>[],
    this.subSubCategory = const <SubSubCategoryRes>[],
    this.subCategoriesProduct = const <ProductResCommon>[],
    this.selectCategory,
    this.categoryIndex = 0,
    this.offset = 0,
    this.hasMore = true,
    this.isFetching = false,
    this.isLoading = false,
    this.activeBrandId,
    this.error,
  });

  final String queryType;
  final int? siteId;
  final List<CategoriesRes> allCategory;
  final List<SubCategoryRes> subCategory;
  final List<SubSubCategoryRes> subSubCategory;
  final List<ProductResCommon> subCategoriesProduct;
  final CategoriesRes? selectCategory;
  final int categoryIndex;
  final int offset;
  final bool hasMore;
  final bool isFetching;
  final bool isLoading;
  final int? activeBrandId;
  final AppFailure? error;

  CategoriesState copyWith({
    String? queryType,
    int? siteId,
    bool clearSiteId = false,
    List<CategoriesRes>? allCategory,
    List<SubCategoryRes>? subCategory,
    List<SubSubCategoryRes>? subSubCategory,
    List<ProductResCommon>? subCategoriesProduct,
    CategoriesRes? selectCategory,
    int? categoryIndex,
    int? offset,
    bool? hasMore,
    bool? isFetching,
    bool? isLoading,
    int? activeBrandId,
    bool clearActiveBrandId = false,
    AppFailure? error,
    bool clearError = false,
  }) {
    return CategoriesState(
      queryType: queryType ?? this.queryType,
      siteId: clearSiteId ? null : siteId ?? this.siteId,
      allCategory: allCategory ?? this.allCategory,
      subCategory: subCategory ?? this.subCategory,
      subSubCategory: subSubCategory ?? this.subSubCategory,
      subCategoriesProduct: subCategoriesProduct ?? this.subCategoriesProduct,
      selectCategory: selectCategory ?? this.selectCategory,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
      isFetching: isFetching ?? this.isFetching,
      isLoading: isLoading ?? this.isLoading,
      activeBrandId: clearActiveBrandId
          ? null
          : activeBrandId ?? this.activeBrandId,
      error: clearError ? null : error ?? this.error,
    );
  }

  List<SubCategoryRes> get filteredSubCategory {
    if (selectCategory == null && categoryIndex == 0) {
      if (allCategory.isEmpty) return const <SubCategoryRes>[];
      return subCategory
          .where((element) => element.categoryId == allCategory.first.id)
          .toList();
    }
    return subCategory
        .where((element) => element.categoryId == selectCategory?.id)
        .toList();
  }

  @override
  List<Object?> get props => [
    queryType,
    siteId,
    allCategory,
    subCategory,
    subSubCategory,
    subCategoriesProduct,
    selectCategory,
    categoryIndex,
    offset,
    hasMore,
    isFetching,
    isLoading,
    activeBrandId,
    error,
  ];
}
