import 'dart:async';

import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/discovery/data/models/store_summary.dart';
import 'package:sellhub/features/discovery/data/store_discovery_repository.dart';

import 'store_discovery_state.dart';

class StoreDiscoveryCubit extends SafeCubit<StoreDiscoveryState> {
  StoreDiscoveryCubit(this._repository) : super(const StoreDiscoveryState());

  final StoreDiscoveryRepository _repository;
  Timer? _searchDebounce;

  Future<void> loadFeatured() async {
    if (state.featuredStores.isNotEmpty) return;
    emit(state.copyWith(loadingFeatured: true, clearError: true));
    try {
      final stores = await _repository.fetchStores(queryType: 'latest');
      emit(state.copyWith(featuredStores: stores, loadingFeatured: false));
    } catch (error) {
      emit(
        state.copyWith(
          loadingFeatured: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load stores.',
          ),
        ),
      );
    }
  }

  Future<void> loadNearby() async {
    emit(state.copyWith(loadingNearby: true, clearError: true));
    try {
      final position = await _repository.resolveCurrentPosition();
      final stores = await _repository.fetchStores(
        queryType: position == null ? 'latest' : 'nearest',
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      emit(state.copyWith(nearbyStores: stores, loadingNearby: false));
    } catch (error) {
      emit(
        state.copyWith(
          loadingNearby: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load nearby stores.',
          ),
        ),
      );
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchResults: const <StoreSummary>[], searching: false));
      return;
    }
    emit(state.copyWith(searching: true, clearError: true));
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final stores = await _repository.fetchStores(search: query, queryType: 'latest');
        emit(state.copyWith(searchResults: stores, searching: false));
      } catch (error) {
        emit(
          state.copyWith(
            searching: false,
            error: AppFailure.fromObject(
              error,
              fallbackTitle: 'Unable to search stores.',
            ),
          ),
        );
      }
    });
  }

  Future<StoreSummary> resolveDomain(String domain) {
    return _repository.resolveByDomain(domain);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
