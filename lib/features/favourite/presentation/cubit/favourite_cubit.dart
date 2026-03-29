import 'package:hive_flutter/hive_flutter.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/utils/constants.dart';
import 'package:sellhub/features/favourite/presentation/cubit/favourite_state.dart';
import 'package:sellhub/features/product/data/models/product_res_common.dart';
import 'package:sellhub/features/product/data/product_repository.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';

class FavouriteCubit extends SafeCubit<FavouriteState> {
  FavouriteCubit(this._profileRepository, this._productRepository)
    : super(const FavouriteState());

  final ProfileRepository _profileRepository;
  final ProductRepository _productRepository;
  Box<ProductResCommon>? _box;

  Future<void> init() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _ensureBox();
      final items = _box!.values.toList();
      final favoriteIds = items
          .map((item) => item.id ?? 0)
          .where((id) => id > 0)
          .toSet();
      emit(
        state.copyWith(
          items: items,
          favoriteIds: favoriteIds,
          isLoading: false,
          clearError: true,
        ),
      );
      await syncFromSession();
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load favourites.',
          ),
        ),
      );
    }
  }

  Future<void> toggleFavourite(ProductResCommon product) async {
    await _ensureBox();
    final productId = product.id;
    if (productId == null) return;

    final session = await _resolveServerSession();
    if (session != null) {
      final isFav = state.favoriteIds.contains(productId);
      final nextIds = Set<int>.from(state.favoriteIds);
      final nextItems = List<ProductResCommon>.from(state.items);
      if (isFav) {
        await _profileRepository.removeFavorite(
          userId: session.userId,
          customerId: session.customerId,
          productId: productId,
        );
        nextIds.remove(productId);
        nextItems.removeWhere((item) => item.id == productId);
      } else {
        await _profileRepository.addFavorite(
          userId: session.userId,
          customerId: session.customerId,
          productId: productId,
        );
        nextIds.add(productId);
        if (nextItems.every((item) => item.id != productId)) {
          nextItems.insert(0, product);
        }
      }
      emit(
        state.copyWith(
          items: nextItems,
          favoriteIds: nextIds,
          clearError: true,
        ),
      );
      return;
    }

    final nextItems = List<ProductResCommon>.from(state.items);
    final nextIds = Set<int>.from(state.favoriteIds);
    final existingIndex = nextItems.indexWhere((item) => item.id == productId);
    if (existingIndex >= 0) {
      await _box?.deleteAt(existingIndex);
      nextItems.removeAt(existingIndex);
      nextIds.remove(productId);
    } else {
      await _box!.add(product);
      nextItems.add(product);
      nextIds.add(productId);
    }
    emit(state.copyWith(items: nextItems, favoriteIds: nextIds, clearError: true));
  }

  bool isFavourite(int productId) {
    return state.favoriteIds.contains(productId);
  }

  Future<void> clear() async {
    await _ensureBox();
    await _box?.clear();
    emit(
      state.copyWith(
        items: const <ProductResCommon>[],
        favoriteIds: const <int>{},
        clearError: true,
      ),
    );
  }

  Future<void> syncFromSession() async {
    try {
      final session = await _resolveServerSession();
      if (session == null) return;

      final selfCustomer = await _profileRepository.fetchSelfStoreCustomer(
        session.userId,
        session.siteId,
      );
      if (selfCustomer == null) return;

      await LocalStorage.saveCustomerID(selfCustomer.id ?? 0);
      final favoriteIds = selfCustomer.favorite.toSet();

      final products = <ProductResCommon>[];
      for (final id in favoriteIds) {
        try {
          final product = await _productRepository.fetchProductById(id);
          if (product != null) {
            products.add(product);
          }
        } catch (_) {}
      }

      emit(
        state.copyWith(
          items: products,
          favoriteIds: favoriteIds,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to sync favourites.',
          ),
        ),
      );
    }
  }

  Future<void> _ensureBox() async {
    if (_box != null) return;
    if (Hive.isBoxOpen(AppConstants.kFavBox)) {
      _box = Hive.box<ProductResCommon>(AppConstants.kFavBox);
    } else {
      _box = await Hive.openBox<ProductResCommon>(AppConstants.kFavBox);
    }
  }

  Future<_FavoriteSession?> _resolveServerSession() async {
    final userId = await LocalStorage.getUserID();
    final store = await LocalStorage.getActiveStore();
    if (userId == null || store == null) return null;

    final customerId = (await LocalStorage.getCustomerID()) ?? 0;
    if (customerId > 0) {
      return _FavoriteSession(
        userId: userId,
        customerId: customerId,
        siteId: store.siteId,
      );
    }

    final selfCustomer = await _profileRepository.fetchSelfStoreCustomer(
      userId,
      store.siteId,
    );
    final resolvedCustomerId = selfCustomer?.id ?? 0;
    if (resolvedCustomerId <= 0) return null;
    await LocalStorage.saveCustomerID(resolvedCustomerId);
    return _FavoriteSession(
      userId: userId,
      customerId: resolvedCustomerId,
      siteId: store.siteId,
    );
  }
}

class _FavoriteSession {
  const _FavoriteSession({
    required this.userId,
    required this.customerId,
    required this.siteId,
  });

  final int userId;
  final int customerId;
  final int siteId;
}
