import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/orders/data/orders_repository.dart';
import 'package:sellhub/features/orders/presentation/cubit/orders_state.dart';

class OrdersCubit extends SafeCubit<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersState());

  final OrdersRepository _repository;
  static const int _customerNoteEventType = 11;
  static const int _issueEventType = 12;
  static const int _buyerContactedEventType = 13;

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
    emit(state.copyWith(filterStatus: status, resetFilter: status == null));
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

  Future<bool> createCustomerIssueRequest({
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
          'Seller raised an issue for $orderLabel. Supplier review is required.',
      failureTitle: 'Unable to raise issue right now.',
      eventType: _issueEventType,
    );
  }

  Future<bool> markBuyerContacted({
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
      note: 'Seller contacted buyer for $orderLabel and logged follow-up.',
      failureTitle: 'Unable to mark buyer as contacted.',
      eventType: _buyerContactedEventType,
    );
  }

  Future<bool> clearCustomerSupportRequest({
    required int siteId,
    required int orderId,
  }) {
    return _deleteCustomerOrderNote(
      siteId: siteId,
      orderId: orderId,
      eventType: _customerNoteEventType,
      failureTitle: 'Unable to clear support request.',
    );
  }

  Future<bool> clearCustomerIssueRequest({
    required int siteId,
    required int orderId,
  }) {
    return _deleteCustomerOrderNote(
      siteId: siteId,
      orderId: orderId,
      eventType: _issueEventType,
      failureTitle: 'Unable to clear issue flag.',
    );
  }

  Future<bool> clearBuyerContacted({
    required int siteId,
    required int orderId,
  }) {
    return _deleteCustomerOrderNote(
      siteId: siteId,
      orderId: orderId,
      eventType: _buyerContactedEventType,
      failureTitle: 'Unable to clear buyer follow-up.',
    );
  }

  Future<bool> _createCustomerOrderNote({
    required int userId,
    required int siteId,
    required int orderId,
    required String orderLabel,
    required String note,
    required String failureTitle,
    int eventType = _customerNoteEventType,
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
        eventType: eventType,
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

  Future<bool> _deleteCustomerOrderNote({
    required int siteId,
    required int orderId,
    required int eventType,
    required String failureTitle,
  }) async {
    if (siteId <= 0 || orderId <= 0) {
      emit(
        state.copyWith(
          actionError: const AppFailure(
            title: 'Unable to complete this action.',
            detail: 'Missing order context.',
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
      final deleted = await _repository.deleteLatestCustomerOrderEvent(
        siteId: siteId,
        orderId: orderId,
        eventType: eventType,
      );
      emit(
        state.copyWith(
          actionSubmitting: false,
          clearActionOrderId: true,
          clearActionError: deleted,
          actionError: deleted
              ? null
              : const AppFailure(
                  title: 'Nothing to clear.',
                  detail: 'No matching local follow-up event was found.',
                ),
        ),
      );
      return deleted;
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
