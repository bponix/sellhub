import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/search/data/search_repository.dart';
import 'package:sellhub/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends SafeCubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchState());

  final SearchRepository _repository;

  void ensureSite(int siteId) {
    if (state.siteId == null || state.siteId == siteId) return;
    emit(
      state.copyWith(
        products: const [],
        searchProducts: const [],
        loading: false,
        siteId: siteId,
        clearError: true,
      ),
    );
  }

  Future<void> search(String text, {required int siteId}) async {
    ensureSite(siteId);
    if (text.isEmpty) {
      emit(
        state.copyWith(
          products: const [],
          searchProducts: const [],
          siteId: siteId,
          clearError: true,
        ),
      );
      return;
    }

    emit(state.copyWith(loading: true, siteId: siteId, clearError: true));
    try {
      final products = await _repository.searchProduct(text, siteId);
      emit(state.copyWith(products: products, loading: false, siteId: siteId));
    } catch (error) {
      emit(
        state.copyWith(
          products: const [],
          loading: false,
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to search products.',
          ),
        ),
      );
    }
  }

  Future<void> searchProductsByButtonClick(
    String search,
    int siteId,
    int first,
  ) async {
    ensureSite(siteId);
    emit(state.copyWith(loading: true, siteId: siteId, clearError: true));
    try {
      final products = await _repository.fetchSearchProductDetails(
        siteId,
        first,
        search,
      );
      emit(
        state.copyWith(
          searchProducts: products,
          loading: false,
          siteId: siteId,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          searchProducts: const [],
          siteId: siteId,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load search results.',
          ),
        ),
      );
    }
  }

  void reset() {
    emit(const SearchState());
  }
}
