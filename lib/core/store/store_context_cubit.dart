import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/capabilities/store_surface_capabilities.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/store/active_store.dart';
import 'package:sellhub/core/store/store_registry.dart';
import 'package:sellhub/core/store/store_context_state.dart';

class StoreContextCubit extends SafeCubit<StoreContextState> {
  StoreContextCubit() : super(const StoreContextState());

  Future<void> hydrate() async {
    emit(state.copyWith(status: StoreContextStatus.loading));
    final store = await LocalStorage.getActiveStore();
    if (store == null) {
      StoreRegistry.currentStore = null;
      emit(state.copyWith(status: StoreContextStatus.none, clearStore: true));
      return;
    }
    StoreRegistry.currentStore = store;
    emit(
      state.copyWith(status: StoreContextStatus.selected, activeStore: store),
    );
  }

  Future<void> setActiveStore(ActiveStore store) async {
    await LocalStorage.saveActiveStore(store);
    await LocalStorage.pushRecentStore(store);
    StoreRegistry.currentStore = store;
    emit(
      state.copyWith(status: StoreContextStatus.selected, activeStore: store),
    );
  }

  Future<void> setActiveStoreWithSurface(
    ActiveStore store,
    StoreSurfaceCapabilitySet surface,
  ) async {
    await LocalStorage.saveActiveStore(store);
    await LocalStorage.pushRecentStore(store);
    StoreRegistry.currentStore = store;
    emit(
      state.copyWith(
        status: StoreContextStatus.selected,
        activeStore: store,
        surfaceCapabilities: surface,
        clearUnavailable: true,
      ),
    );
  }

  Future<void> markUnavailable({
    required ActiveStore store,
    required StoreSurfaceCapabilitySet? surface,
    required String title,
    required String message,
  }) async {
    await LocalStorage.saveActiveStore(store);
    await LocalStorage.pushRecentStore(store);
    StoreRegistry.currentStore = store;
    emit(
      state.copyWith(
        status: StoreContextStatus.unavailable,
        activeStore: store,
        surfaceCapabilities: surface,
        unavailableTitle: title,
        unavailableMessage: message,
      ),
    );
  }

  Future<void> clear() async {
    await LocalStorage.clearActiveStore();
    StoreRegistry.currentStore = null;
    emit(
      state.copyWith(
        status: StoreContextStatus.none,
        clearStore: true,
        clearSurface: true,
        clearUnavailable: true,
      ),
    );
  }
}
