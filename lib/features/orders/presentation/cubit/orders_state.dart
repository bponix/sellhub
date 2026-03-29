import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';

class OrdersState extends Equatable {
  const OrdersState({
    this.orders = const <OrderHistoryResModelProfile>[],
    this.filterStatus,
    this.loading = false,
    this.error,
    this.actionOrderId,
    this.actionSubmitting = false,
    this.actionError,
  });

  final List<OrderHistoryResModelProfile> orders;
  final int? filterStatus;
  final bool loading;
  final AppFailure? error;
  final int? actionOrderId;
  final bool actionSubmitting;
  final AppFailure? actionError;

  List<OrderHistoryResModelProfile> get filteredOrders {
    if (filterStatus == null) return orders;
    return orders.where((order) => order.status == filterStatus).toList();
  }

  OrdersState copyWith({
    List<OrderHistoryResModelProfile>? orders,
    int? filterStatus,
    bool resetFilter = false,
    bool? loading,
    AppFailure? error,
    bool clearError = false,
    int? actionOrderId,
    bool clearActionOrderId = false,
    bool? actionSubmitting,
    AppFailure? actionError,
    bool clearActionError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      filterStatus: resetFilter ? null : filterStatus ?? this.filterStatus,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      actionOrderId: clearActionOrderId
          ? null
          : actionOrderId ?? this.actionOrderId,
      actionSubmitting: actionSubmitting ?? this.actionSubmitting,
      actionError: clearActionError ? null : actionError ?? this.actionError,
    );
  }

  @override
  List<Object?> get props => [
        orders,
        filterStatus,
        loading,
        error,
        actionOrderId,
        actionSubmitting,
        actionError,
      ];
}
