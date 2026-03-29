import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/categories/data/categories_repositopry.dart';
import 'package:sellhub/features/categories/presentation/cubit/categories_state.dart';
import 'package:sellhub/features/product/data/models/category_res.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class CategoriesCubit extends SafeCubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState());

  final CategoryRepository _repository;

  void ensureSite(int siteId) {
    if (state.siteId == null || state.siteId == siteId) return;
    emit(
      CategoriesState(
        siteId: siteId,
      ),
    );
  }

  void reset() {
    emit(const CategoriesState());
  }

  Future<void> fetchAllCategory(int siteId) async {
    ensureSite(siteId);
    if (state.allCategory.isNotEmpty) return;
    try {
      final data = await _repository.fetchCategories(siteId);
      emit(
        state.copyWith(
          siteId: siteId,
          allCategory: data,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load categories.',
          ),
        ),
      );
    }
  }

  Future<void> fetchSubCategory(int siteId) async {
    ensureSite(siteId);
    if (state.subCategory.isNotEmpty) return;
    await fetchAllCategory(siteId);
    try {
      final data = await _repository.fetchSubCategories(siteId);
      emit(
        state.copyWith(
          siteId: siteId,
          subCategory: data,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load sub categories.',
          ),
        ),
      );
    }
  }

  Future<void> fetchSubSubCategory(int siteId) async {
    ensureSite(siteId);
    if (state.subSubCategory.isNotEmpty) return;
    try {
      final data = await _repository.fetchSubSubCategories(siteId);
      emit(
        state.copyWith(
          siteId: siteId,
          subSubCategory: data,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load nested categories.',
          ),
        ),
      );
    }
  }

  void setCategoryIndex(int index, CategoriesRes category) {
    emit(state.copyWith(categoryIndex: index, selectCategory: category));
  }

  void queryTypeSet(
    String type,
    bool seeAll,
    int id,
    int siteId,
    int first, {
    int? brandId,
  }) {
    emit(
      state.copyWith(
        queryType: type,
        activeBrandId: brandId,
        clearActiveBrandId: brandId == null,
      ),
    );
    if (brandId != null) {
      fetchBrandProducts(siteId, first, brandId, 0);
      return;
    }
    if (seeAll) {
      fetchCategoriesAllProduct(siteId, first, id, 0);
    } else {
      fetchSubCategoriesProduct(siteId, first, id, 0);
    }
  }

  Future<void> fetchSubCategoriesProduct(
    int siteId,
    int first,
    int subCategoryId,
    int offset, {
    bool isLoadMore = false,
    int? brandId,
  }) async {
    if (state.isFetching) return;
    ensureSite(siteId);
    emit(
      state.copyWith(
        siteId: siteId,
        activeBrandId: brandId,
        clearActiveBrandId: brandId == null,
        isFetching: isLoadMore,
        isLoading: !isLoadMore,
        offset: isLoadMore ? state.offset : 0,
        hasMore: isLoadMore ? state.hasMore : true,
        subCategoriesProduct: isLoadMore
            ? state.subCategoriesProduct
            : const <ProductResCommon>[],
        clearError: true,
      ),
    );
    try {
      final items = await _repository.fetchSubCategoriesProducts(
        siteId,
        subCategoryId,
        first,
        offset,
        state.queryType,
        brandId: brandId ?? state.activeBrandId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          subCategoriesProduct: isLoadMore
              ? [...state.subCategoriesProduct, ...items]
              : items,
          offset: offset + first,
          hasMore: items.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load products.',
          ),
        ),
      );
    }
  }

  Future<void> fetchCategoriesAllProduct(
    int siteId,
    int first,
    int categoryId,
    int offset, {
    bool isLoadMore = false,
    int? brandId,
  }) async {
    if (state.isFetching) return;
    ensureSite(siteId);
    emit(
      state.copyWith(
        siteId: siteId,
        activeBrandId: brandId,
        clearActiveBrandId: brandId == null,
        isFetching: isLoadMore,
        isLoading: !isLoadMore,
        offset: isLoadMore ? state.offset : 0,
        hasMore: isLoadMore ? state.hasMore : true,
        subCategoriesProduct: isLoadMore
            ? state.subCategoriesProduct
            : const <ProductResCommon>[],
        clearError: true,
      ),
    );
    try {
      final items = await _repository.fetchCategoriesAllProduct(
        siteId,
        categoryId,
        first,
        offset,
        state.queryType,
        brandId: brandId ?? state.activeBrandId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          subCategoriesProduct: isLoadMore
              ? [...state.subCategoriesProduct, ...items]
              : items,
          offset: offset + first,
          hasMore: items.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load category products.',
          ),
        ),
      );
    }
  }

  void loadMoreData(
    int siteId,
    int subCategoryId,
    int first,
    bool seeAll,
    int categoryId,
    int? brandId,
  ) {
    if (!state.hasMore) return;
    if (brandId != null) {
      fetchBrandProducts(
        siteId,
        first,
        brandId,
        state.offset,
        isLoadMore: true,
      );
      return;
    }
    if (seeAll) {
      fetchCategoriesAllProduct(
        siteId,
        first,
        categoryId,
        state.offset,
        isLoadMore: true,
      );
      return;
    }
    fetchSubCategoriesProduct(
      siteId,
      first,
      subCategoryId,
      state.offset,
      isLoadMore: true,
    );
  }

  Future<void> fetchBrandProducts(
    int siteId,
    int first,
    int brandId,
    int offset, {
    bool isLoadMore = false,
  }) async {
    if (state.isFetching) return;
    ensureSite(siteId);
    emit(
      state.copyWith(
        siteId: siteId,
        activeBrandId: brandId,
        isFetching: isLoadMore,
        isLoading: !isLoadMore,
        offset: isLoadMore ? state.offset : 0,
        hasMore: isLoadMore ? state.hasMore : true,
        subCategoriesProduct: isLoadMore
            ? state.subCategoriesProduct
            : const <ProductResCommon>[],
        clearError: true,
      ),
    );
    try {
      final items = await _repository.fetchCategoriesAllProduct(
        siteId,
        0,
        first,
        offset,
        state.queryType,
        brandId: brandId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          subCategoriesProduct: isLoadMore
              ? [...state.subCategoriesProduct, ...items]
              : items,
          offset: offset + first,
          hasMore: items.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetching: false,
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load brand products.',
          ),
        ),
      );
    }
  }
}
