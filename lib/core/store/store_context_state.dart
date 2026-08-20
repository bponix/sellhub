import 'package:equatable/equatable.dart';
import 'package:sellhub/core/capabilities/store_surface_capabilities.dart';
import 'package:sellhub/core/store/active_store.dart';

enum StoreContextStatus { initial, loading, none, selected, unavailable }

class StoreContextState extends Equatable {
  const StoreContextState({
    this.status = StoreContextStatus.initial,
    this.activeStore,
    this.surfaceCapabilities,
    this.unavailableTitle,
    this.unavailableMessage,
  });

  final StoreContextStatus status;
  final ActiveStore? activeStore;
  final StoreSurfaceCapabilitySet? surfaceCapabilities;
  final String? unavailableTitle;
  final String? unavailableMessage;

  StoreContextState copyWith({
    StoreContextStatus? status,
    ActiveStore? activeStore,
    StoreSurfaceCapabilitySet? surfaceCapabilities,
    String? unavailableTitle,
    String? unavailableMessage,
    bool clearStore = false,
    bool clearSurface = false,
    bool clearUnavailable = false,
  }) {
    return StoreContextState(
      status: status ?? this.status,
      activeStore: clearStore ? null : activeStore ?? this.activeStore,
      surfaceCapabilities: clearSurface
          ? null
          : surfaceCapabilities ?? this.surfaceCapabilities,
      unavailableTitle: clearUnavailable
          ? null
          : unavailableTitle ?? this.unavailableTitle,
      unavailableMessage: clearUnavailable
          ? null
          : unavailableMessage ?? this.unavailableMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    activeStore,
    surfaceCapabilities,
    unavailableTitle,
    unavailableMessage,
  ];
}
