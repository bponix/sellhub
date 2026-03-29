import 'package:sellhub/core/bloc/safe_cubit.dart';
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
      state.copyWith(
        status: StoreContextStatus.selected,
        activeStore: store,
      ),
    );
  }

  Future<void> setActiveStore(ActiveStore store) async {
    await LocalStorage.saveActiveStore(store);
    await LocalStorage.pushRecentStore(store);
    StoreRegistry.currentStore = store;
    emit(
      state.copyWith(
        status: StoreContextStatus.selected,
        activeStore: store,
      ),
    );
  }

  Future<void> clear() async {
    await LocalStorage.clearActiveStore();
    StoreRegistry.currentStore = null;
    emit(state.copyWith(status: StoreContextStatus.none, clearStore: true));
  }
}
