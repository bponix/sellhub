import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/search/data/models/search_product_res.dart';

class SearchState extends Equatable {
  const SearchState({
    this.products = const <SearchProductRes>[],
    this.searchProducts = const <ProductResCommon>[],
    this.loading = false,
    this.siteId,
    this.error,
  });

  final List<SearchProductRes> products;
  final List<ProductResCommon> searchProducts;
  final bool loading;
  final int? siteId;
  final AppFailure? error;

  SearchState copyWith({
    List<SearchProductRes>? products,
    List<ProductResCommon>? searchProducts,
    bool? loading,
    int? siteId,
    bool clearSiteId = false,
    AppFailure? error,
    bool clearError = false,
  }) {
    return SearchState(
      products: products ?? this.products,
      searchProducts: searchProducts ?? this.searchProducts,
      loading: loading ?? this.loading,
      siteId: clearSiteId ? null : siteId ?? this.siteId,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [products, searchProducts, loading, siteId, error];
}
