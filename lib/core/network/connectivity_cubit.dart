import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';

enum ConnectivityStatus { unknown, online, offline }

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.status = ConnectivityStatus.unknown,
    this.activeConnections = const <ConnectivityResult>[],
  });

  final ConnectivityStatus status;
  final List<ConnectivityResult> activeConnections;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    List<ConnectivityResult>? activeConnections,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      activeConnections: activeConnections ?? this.activeConnections,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, activeConnections];
}

class ConnectivityCubit extends SafeCubit<ConnectivityState> {
  ConnectivityCubit(this._connectivity) : super(const ConnectivityState());

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    final initial = await _connectivity.checkConnectivity();
    _emitStatus(initial);
    await _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(_emitStatus);
  }

  void _emitStatus(List<ConnectivityResult> results) {
    final unique = results.toSet().toList();
    final isOffline =
        unique.isEmpty ||
        unique.every((result) => result == ConnectivityResult.none);
    emit(
      state.copyWith(
        status: isOffline
            ? ConnectivityStatus.offline
            : ConnectivityStatus.online,
        activeConnections: unique,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
