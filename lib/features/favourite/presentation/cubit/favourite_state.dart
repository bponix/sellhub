import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';

class FavouriteState extends Equatable {
  const FavouriteState({
    this.items = const <ProductResCommon>[],
    this.favoriteIds = const <int>{},
    this.isLoading = false,
    this.error,
  });

  final List<ProductResCommon> items;
  final Set<int> favoriteIds;
  final bool isLoading;
  final AppFailure? error;

  FavouriteState copyWith({
    List<ProductResCommon>? items,
    Set<int>? favoriteIds,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
  }) {
    return FavouriteState(
      items: items ?? this.items,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [items, favoriteIds, isLoading, error];
}
