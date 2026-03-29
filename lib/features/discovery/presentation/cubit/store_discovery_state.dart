import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';

class StoreDiscoveryState extends Equatable {
  const StoreDiscoveryState({
    this.featuredStores = const <StoreSummary>[],
    this.nearbyStores = const <StoreSummary>[],
    this.searchResults = const <StoreSummary>[],
    this.loadingFeatured = false,
    this.loadingNearby = false,
    this.searching = false,
    this.error,
  });

  final List<StoreSummary> featuredStores;
  final List<StoreSummary> nearbyStores;
  final List<StoreSummary> searchResults;
  final bool loadingFeatured;
  final bool loadingNearby;
  final bool searching;
  final AppFailure? error;

  StoreDiscoveryState copyWith({
    List<StoreSummary>? featuredStores,
    List<StoreSummary>? nearbyStores,
    List<StoreSummary>? searchResults,
    bool? loadingFeatured,
    bool? loadingNearby,
    bool? searching,
    AppFailure? error,
    bool clearError = false,
  }) {
    return StoreDiscoveryState(
      featuredStores: featuredStores ?? this.featuredStores,
      nearbyStores: nearbyStores ?? this.nearbyStores,
      searchResults: searchResults ?? this.searchResults,
      loadingFeatured: loadingFeatured ?? this.loadingFeatured,
      loadingNearby: loadingNearby ?? this.loadingNearby,
      searching: searching ?? this.searching,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    featuredStores,
    nearbyStores,
    searchResults,
    loadingFeatured,
    loadingNearby,
    searching,
    error,
  ];
}
