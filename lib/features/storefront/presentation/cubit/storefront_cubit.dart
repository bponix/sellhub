import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/storefront/domain/repositories/storefront_repository.dart';
import 'package:sellhub/features/storefront/domain/usecases/preload_storefront.dart';
import 'package:sellhub/features/storefront/presentation/cubit/storefront_state.dart';

class StorefrontCubit extends SafeCubit<StorefrontState> {
  StorefrontCubit({
    required StorefrontRepository repository,
    required PreloadStorefront preloadStorefront,
  }) : _repository = repository,
       _preloadStorefront = preloadStorefront,
       super(const StorefrontState());

  final StorefrontRepository _repository;
  final PreloadStorefront _preloadStorefront;

  Future<void> preload({
    required String domain,
    required int siteId,
    required int first,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && state.status == StorefrontStatus.success) return;
    emit(
      state.copyWith(
        isLoading: true,
        status: StorefrontStatus.loading,
        clearError: true,
      ),
    );
    try {
      final data = await _preloadStorefront(
        domain: domain,
        siteId: siteId,
        first: first,
      );
      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          isLoading: false,
          siteDetails: data.site,
          products: data.products,
          allCategory: data.categories,
          siteSlider: data.siteSliders,
          flashSale: data.flashSale,
          newArrival: data.newArrival,
          topBrand: data.topBrand,
          popularOffset: first,
          flashSaleOffset: first,
          newArrivalOffset: first,
          categoryOffset: 0,
          hasMorePopular: data.products.length >= first,
          hasMoreFlashSale: data.flashSale.length >= first,
          hasMoreNewArrival: data.newArrival.length >= first,
          hasMoreCategoryProduct: true,
          categoriesProduct: const <ProductResCommon>[],
          homeCategoryProducts: const <int, List<ProductResCommon>>{},
          homeCategoryLoading: false,
          degradedSections: data.degradedSections,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StorefrontStatus.failure,
          isLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load storefront.',
          ),
        ),
      );
    }
  }

  void clear() {
    emit(const StorefrontState());
  }

  void setCategoryIndex(int index) {
    emit(state.copyWith(categoryIndex: index));
  }

  Future<void> fetchProducts(
    int siteId,
    int first,
    int offset, {
    bool isLoadMore = false,
  }) async {
    if (state.isFetchingMore || (!isLoadMore && state.products.isNotEmpty)) {
      return;
    }
    emit(
      state.copyWith(
        isLoading: !isLoadMore,
        isFetchingMore: isLoadMore,
        clearError: true,
      ),
    );
    try {
      final newItems = await _repository.fetchProducts(siteId, first, offset);
      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          isLoading: false,
          isFetchingMore: false,
          products: isLoadMore ? [...state.products, ...newItems] : newItems,
          popularOffset: offset + first,
          hasMorePopular: newItems.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetchingMore: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load products.',
          ),
        ),
      );
    }
  }

  Future<void> fetchSiteDetails(String domain) async {
    if (state.siteDetails != null) return;
    try {
      final data = await _repository.fetchSiteInformation(domain);
      emit(state.copyWith(siteDetails: data, status: StorefrontStatus.success));
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load store details.',
          ),
        ),
      );
    }
  }

  Future<void> fetchSiteSlider(int siteId) async {
    if (state.siteSlider.isNotEmpty) return;
    final data = await _repository.fetchSiteSlider(siteId);
    emit(state.copyWith(siteSlider: data, status: StorefrontStatus.success));
  }

  Future<void> fetchAllCategory(int siteId) async {
    if (state.allCategory.isNotEmpty) return;
    final data = await _repository.fetchCategories(siteId);
    emit(state.copyWith(allCategory: data, status: StorefrontStatus.success));
  }

  Future<void> fetchFlashSale(
    int siteId,
    int first,
    int offset, {
    bool isLoadMore = false,
  }) async {
    if (state.isFetchingMore || (!isLoadMore && state.flashSale.isNotEmpty)) {
      return;
    }
    emit(
      state.copyWith(
        isLoading: !isLoadMore,
        isFetchingMore: isLoadMore,
        clearError: true,
      ),
    );
    try {
      final newItems = await _repository.fetchFlashSale(siteId, first, offset);
      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          isLoading: false,
          isFetchingMore: false,
          flashSale: isLoadMore ? [...state.flashSale, ...newItems] : newItems,
          flashSaleOffset: offset + first,
          hasMoreFlashSale: newItems.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetchingMore: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load flash sale.',
          ),
        ),
      );
    }
  }

  Future<void> fetchNewArrival(
    int siteId,
    int first,
    int offset, {
    bool isLoadMore = false,
  }) async {
    if (state.isFetchingMore || (!isLoadMore && state.newArrival.isNotEmpty)) {
      return;
    }
    emit(
      state.copyWith(
        isLoading: !isLoadMore,
        isFetchingMore: isLoadMore,
        clearError: true,
      ),
    );
    try {
      final newItems = await _repository.fetchNewArrival(siteId, first, offset);
      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          isLoading: false,
          isFetchingMore: false,
          newArrival: isLoadMore
              ? [...state.newArrival, ...newItems]
              : newItems,
          newArrivalOffset: offset + first,
          hasMoreNewArrival: newItems.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isFetchingMore: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load new arrivals.',
          ),
        ),
      );
    }
  }

  Future<void> fetchTopBrand(int siteId) async {
    final data = await _repository.fetchTopBrand(siteId);
    emit(state.copyWith(topBrand: data, status: StorefrontStatus.success));
  }

  Future<void> fetchCategoriesProduct(
    int siteId,
    int categoryId,
    int first,
    int offset, {
    bool isLoadMore = false,
  }) async {
    if (state.isFetchingMore) return;
    emit(
      state.copyWith(
        allCategoryLoading: !isLoadMore,
        isFetchingMore: isLoadMore,
        categoriesProduct: isLoadMore
            ? state.categoriesProduct
            : const <ProductResCommon>[],
        categoryOffset: isLoadMore ? state.categoryOffset : 0,
        hasMoreCategoryProduct: isLoadMore
            ? state.hasMoreCategoryProduct
            : true,
        clearError: true,
      ),
    );
    try {
      final newItems = await _repository.fetchCategoryProduct(
        siteId,
        categoryId,
        first,
        offset,
      );
      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          allCategoryLoading: false,
          isFetchingMore: false,
          categoriesProduct: isLoadMore
              ? [...state.categoriesProduct, ...newItems]
              : newItems,
          categoryOffset: offset + first,
          hasMoreCategoryProduct: newItems.length >= first,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          allCategoryLoading: false,
          isFetchingMore: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load category products.',
          ),
        ),
      );
    }
  }

  Future<void> ensureHomeCategorySections(
    int siteId,
    int first, {
    int maxSections = 4,
  }) async {
    if (state.homeCategoryLoading || state.allCategory.isEmpty) {
      return;
    }

    final targetCategories = state.allCategory
        .where((category) => category.id != null)
        .take(maxSections)
        .toList(growable: false);

    if (targetCategories.isEmpty) {
      return;
    }

    final missingCategories = targetCategories
        .where(
          (category) => !state.homeCategoryProducts.containsKey(category.id),
        )
        .toList(growable: false);

    if (missingCategories.isEmpty) {
      return;
    }

    emit(state.copyWith(homeCategoryLoading: true, clearError: true));

    try {
      final nextSections = Map<int, List<ProductResCommon>>.from(
        state.homeCategoryProducts,
      );

      for (final category in missingCategories) {
        final categoryId = category.id;
        if (categoryId == null) {
          continue;
        }
        final products = await _repository.fetchCategoryProduct(
          siteId,
          categoryId,
          first,
          0,
        );
        nextSections[categoryId] = products;
      }

      emit(
        state.copyWith(
          status: StorefrontStatus.success,
          homeCategoryLoading: false,
          homeCategoryProducts: nextSections,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          homeCategoryLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load category sections.',
          ),
        ),
      );
    }
  }

  void loadMoreData(
    int siteId,
    int first,
    int? categoryId,
    bool isFlash,
    bool isNew,
  ) {
    if (categoryId == null || categoryId == 0) {
      if (state.hasMorePopular && !isFlash && !isNew) {
        fetchProducts(siteId, first, state.popularOffset, isLoadMore: true);
      }
      if (state.hasMoreFlashSale && isFlash) {
        fetchFlashSale(siteId, first, state.flashSaleOffset, isLoadMore: true);
      }
      if (state.hasMoreNewArrival && isNew) {
        fetchNewArrival(
          siteId,
          first,
          state.newArrivalOffset,
          isLoadMore: true,
        );
      }
      return;
    }

    if (state.hasMoreCategoryProduct) {
      fetchCategoriesProduct(
        siteId,
        categoryId,
        first,
        state.categoryOffset,
        isLoadMore: true,
      );
    }
  }
}
