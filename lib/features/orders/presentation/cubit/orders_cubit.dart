import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';

class OrdersCubit extends SafeCubit<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersState());

  final OrdersRepository _repository;
  static const int _customerNoteEventType = 11;

  Future<void> fetchOrders({
    required int siteId,
    required int customerId,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final orders = await _repository.fetchOrders(
        siteId: siteId,
        customerId: customerId,
      );
      emit(state.copyWith(orders: orders, loading: false, clearError: true));
    } catch (error) {
      emit(
        state.copyWith(
          loading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load orders.',
          ),
        ),
      );
    }
  }

  void setFilter(int? status) {
    emit(
      state.copyWith(
        filterStatus: status,
        resetFilter: status == null,
      ),
    );
  }

  Future<bool> createCustomerSupportRequest({
    required int userId,
    required int siteId,
    required int orderId,
    required String orderLabel,
  }) {
    return _createCustomerOrderNote(
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      orderLabel: orderLabel,
      note:
          'Customer requested support for $orderLabel. Please follow up with the customer.',
      failureTitle: 'Unable to send support request.',
    );
  }

  Future<bool> createCustomerCancelRequest({
    required int userId,
    required int siteId,
    required int orderId,
    required String orderLabel,
  }) {
    return _createCustomerOrderNote(
      userId: userId,
      siteId: siteId,
      orderId: orderId,
      orderLabel: orderLabel,
      note:
          'Customer requested cancellation for $orderLabel. Please review before shipment.',
      failureTitle: 'Unable to send cancellation request.',
    );
  }

  Future<bool> _createCustomerOrderNote({
    required int userId,
    required int siteId,
    required int orderId,
    required String orderLabel,
    required String note,
    required String failureTitle,
  }) async {
    if (userId <= 0 || siteId <= 0 || orderId <= 0) {
      emit(
        state.copyWith(
          actionError: const AppFailure(
            title: 'Unable to complete this action.',
            detail: 'Missing order or session context.',
          ),
          clearActionError: false,
          actionSubmitting: false,
          clearActionOrderId: true,
        ),
      );
      return false;
    }

    emit(
      state.copyWith(
        actionOrderId: orderId,
        actionSubmitting: true,
        clearActionError: true,
      ),
    );
    try {
      await _repository.createCustomerOrderEvent(
        userId: userId,
        siteId: siteId,
        orderId: orderId,
        eventType: _customerNoteEventType,
        note: note,
      );
      emit(
        state.copyWith(
          actionSubmitting: false,
          clearActionOrderId: true,
          clearActionError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          actionSubmitting: false,
          clearActionOrderId: true,
          actionError: AppFailure.fromObject(
            error,
            fallbackTitle: failureTitle,
          ),
        ),
      );
      return false;
    }
  }
}
