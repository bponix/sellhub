import 'package:equatable/equatable.dart';
import 'package:sellhub/core/store/active_store.dart';

enum StoreContextStatus { initial, loading, none, selected }

class StoreContextState extends Equatable {
  const StoreContextState({
    this.status = StoreContextStatus.initial,
    this.activeStore,
  });

  final StoreContextStatus status;
  final ActiveStore? activeStore;

  StoreContextState copyWith({
    StoreContextStatus? status,
    ActiveStore? activeStore,
    bool clearStore = false,
  }) {
    return StoreContextState(
      status: status ?? this.status,
      activeStore: clearStore ? null : activeStore ?? this.activeStore,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, activeStore];
}
