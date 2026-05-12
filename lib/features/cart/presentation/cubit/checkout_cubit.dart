import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bkash/flutter_bkash.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/config/payment_config.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/core/pricing/smart_pricing.dart';
import 'package:sellhub/features/cart/data/checkout_repository.dart';
import 'package:sellhub/features/cart/data/models/order_create_req.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/payment_gateway_response.dart';
import 'package:sellhub/features/cart/data/models/payment_success.dart';
import 'package:sellhub/features/cart/data/models/paymentgateway_req.dart';
import 'package:sellhub/features/cart/data/models/reseller_quote.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/cart/presentation/cubit/checkout_state.dart';

class CheckoutCubit extends SafeCubit<CheckoutState> {
  CheckoutCubit(this._repository) : super(const CheckoutState());

  final CheckoutRepository _repository;

  List<DeliveryPlaceRes> _sanitizeDeliveryPlaces(
    List<DeliveryPlaceRes> places,
  ) {
    return places
        .where(
          (place) =>
              place.id != null &&
              place.id! > 0 &&
              (place.isActive ?? true) &&
              (place.title?.trim().isNotEmpty ?? false),
        )
        .toList(growable: false);
  }

  List<PaymentMethodRes> _sanitizePaymentMethods(
    List<PaymentMethodRes> methods,
  ) {
    final filtered = methods
        .where(
          (method) =>
              method.id != null &&
              method.id! > 0 &&
              (method.isActive ?? true) &&
              (method.title?.trim().isNotEmpty ?? false),
        )
        .toList(growable: false);
    filtered.sort(
      (a, b) => (a.priority ?? 1 << 30).compareTo(b.priority ?? 1 << 30),
    );
    return filtered;
  }

  void setDeliveryCharge(double charge) {
    emit(state.copyWith(deliveryCharge: charge));
  }

  void setDeliveryWay(String place) {
    emit(state.copyWith(deliveryWay: place));
  }

  void setLogisticId(int id) {
    emit(state.copyWith(logisticId: id));
  }

  void setGatewayText(String text) {
    emit(state.copyWith(gateWayText: text));
  }

  void setAreaSelect(int value) {
    emit(state.copyWith(areaSelect: value));
  }

  void setPaySelect(int value) {
    emit(state.copyWith(paySelect: value));
  }

  void selectShippingAddress(StoreCustomerAddressModel? address) {
    emit(state.copyWith(selectedShippingAddressId: address?.id));
  }

  Future<void> fetchDeliveryPlace(int siteUserId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final places = _sanitizeDeliveryPlaces(
        await _repository.fetchDeliveryPlace(siteUserId),
      );
      emit(
        state.copyWith(
          isLoading: false,
          deliveryPlace: places,
          areaSelect: places.isEmpty ? 0 : 0,
          logisticId: places.isEmpty ? 0 : (places.first.id ?? 0),
          deliveryCharge: places.isEmpty
              ? 0
              : (places.first.chargeMerchantDefined ?? 0),
          deliveryWay: places.isEmpty ? '' : (places.first.title ?? ''),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          deliveryPlace: const <DeliveryPlaceRes>[],
          areaSelect: 0,
          logisticId: 0,
          deliveryCharge: 0,
          deliveryWay: '',
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load delivery areas.',
          ),
        ),
      );
    }
  }

  Future<void> fetchPaymentMethod(int siteId) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final methods = _sanitizePaymentMethods(
        await _repository.fetchPaymentMethod(siteId),
      );
      emit(
        state.copyWith(
          isLoading: false,
          paymentMethod: methods,
          paySelect: methods.isEmpty ? 0 : 0,
          gateWayText: methods.isEmpty ? '' : (methods.first.title ?? ''),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          paymentMethod: const <PaymentMethodRes>[],
          paySelect: 0,
          gateWayText: '',
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load payment methods.',
          ),
        ),
      );
    }
  }

  Future<Map<int, ProductPricingMemory>> fetchPricingMemories({
    required int userId,
    required int siteId,
    required List<int> productIds,
  }) {
    return _repository.fetchPricingMemories(
      userId: userId,
      siteId: siteId,
      productIds: productIds,
    );
  }

  Future<ResellerQuote> createQuote(ResellerQuote quote) {
    return _repository.createQuote(quote);
  }

  Future<void> markQuoteConverted({
    required String quoteId,
    required String orderId,
  }) {
    return _repository.markQuoteConverted(quoteId: quoteId, orderId: orderId);
  }

  Future<bool> deleteQuote(String quoteId) {
    return _repository.deleteQuote(quoteId);
  }

  Future<void> hydrateCustomerContext({
    required int userId,
    required int siteId,
  }) async {
    try {
      final customer = await _repository.fetchCustomerContext(
        userId: userId,
        siteId: siteId,
      );
      await LocalStorage.saveCustomerID(customer?.id ?? 0);
      emit(
        state.copyWith(
          customerId: customer?.id ?? 0,
          savedBillingAddresses:
              customer?.billingAddress ?? const <StoreCustomerAddressModel>[],
          savedShippingAddresses:
              customer?.shippingAddress ?? const <StoreCustomerAddressModel>[],
          selectedShippingAddressId:
              customer?.shippingAddress.isNotEmpty == true
              ? customer!.shippingAddress.first.id
              : null,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load saved addresses.',
          ),
        ),
      );
    }
  }

  Future<bool> saveShippingAddress({
    required int customerId,
    required String address,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return false;
    final model = StoreCustomerAddressModel(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647,
      address: trimmed,
      formattedAddress: trimmed,
      latitude: 0,
      longitude: 0,
    );
    try {
      final success = await _repository.addShippingAddress(
        customerId: customerId,
        address: model,
      );
      if (!success) return false;
      emit(
        state.copyWith(
          savedShippingAddresses: <StoreCustomerAddressModel>[
            model,
            ...state.savedShippingAddresses,
          ],
          selectedShippingAddressId: model.id,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to save address.',
          ),
        ),
      );
      return false;
    }
  }

  void setQuickOrderDraft(Map<String, dynamic>? draft) {
    emit(
      state.copyWith(
        quickOrderDraftStatus: draft == null
            ? CheckoutResourceStatus.initial
            : CheckoutResourceStatus.success,
        quickOrderDraft: draft,
        clearQuickOrderDraft: draft == null,
        clearError: true,
      ),
    );
  }

  Future<Map<String, dynamic>?> loadQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    emit(
      state.copyWith(
        quickOrderDraftStatus: CheckoutResourceStatus.loading,
        clearError: true,
      ),
    );
    try {
      final draft = await _repository.fetchQuickOrderDraft(
        userId: userId,
        siteId: siteId,
        draftId: draftId,
      );
      emit(
        state.copyWith(
          quickOrderDraftStatus: CheckoutResourceStatus.success,
          quickOrderDraft: draft,
          clearQuickOrderDraft: draft == null,
          clearError: true,
        ),
      );
      return draft;
    } catch (error) {
      emit(
        state.copyWith(
          quickOrderDraftStatus: CheckoutResourceStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load quick-order draft.',
          ),
        ),
      );
      return null;
    }
  }

  Future<Map<String, dynamic>> saveQuickOrderDraft({
    required int userId,
    required int siteId,
    required Map<String, dynamic> draft,
  }) async {
    emit(
      state.copyWith(
        quickOrderDraftStatus: CheckoutResourceStatus.loading,
        clearError: true,
      ),
    );
    try {
      final savedDraft = await _repository.saveQuickOrderDraft(
        userId: userId,
        siteId: siteId,
        draft: draft,
      );
      emit(
        state.copyWith(
          quickOrderDraftStatus: CheckoutResourceStatus.success,
          quickOrderDraft: savedDraft,
          clearError: true,
        ),
      );
      return savedDraft;
    } catch (error) {
      emit(
        state.copyWith(
          quickOrderDraftStatus: CheckoutResourceStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to save quick-order draft.',
          ),
        ),
      );
      rethrow;
    }
  }

  Future<bool> deleteQuickOrderDraft({
    required int userId,
    required int siteId,
    String? draftId,
  }) async {
    emit(
      state.copyWith(
        quickOrderDraftStatus: CheckoutResourceStatus.loading,
        clearError: true,
      ),
    );
    try {
      final deleted = await _repository.deleteQuickOrderDraft(
        userId: userId,
        siteId: siteId,
        draftId: draftId,
      );
      emit(
        state.copyWith(
          quickOrderDraftStatus: deleted
              ? CheckoutResourceStatus.initial
              : CheckoutResourceStatus.success,
          clearQuickOrderDraft: deleted,
          clearError: true,
        ),
      );
      return deleted;
    } catch (error) {
      emit(
        state.copyWith(
          quickOrderDraftStatus: CheckoutResourceStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to delete quick-order draft.',
          ),
        ),
      );
      return false;
    }
  }

  void clearQuickOrderDraftState({bool resetStatus = true}) {
    emit(
      state.copyWith(
        quickOrderDraftStatus: resetStatus
            ? CheckoutResourceStatus.initial
            : state.quickOrderDraftStatus,
        clearQuickOrderDraft: true,
        clearError: true,
      ),
    );
  }

  Future<Map<String, dynamic>> fetchBuyerRiskDecision({
    required int userId,
    required int siteId,
    required String buyerPhone,
    String? buyerName,
    String? buyerAddress,
    double? orderTotal,
    int? itemCount,
    Map<String, dynamic>? context,
  }) async {
    emit(
      state.copyWith(
        buyerRiskDecisionStatus: CheckoutResourceStatus.loading,
        clearError: true,
      ),
    );
    try {
      final decision = await _repository.fetchBuyerRiskDecision(
        userId: userId,
        siteId: siteId,
        buyerPhone: buyerPhone,
        buyerName: buyerName,
        buyerAddress: buyerAddress,
        orderTotal: orderTotal,
        itemCount: itemCount,
        context: context,
      );
      emit(
        state.copyWith(
          buyerRiskDecisionStatus: CheckoutResourceStatus.success,
          buyerRiskDecision: decision,
          clearError: true,
        ),
      );
      return decision;
    } catch (error) {
      emit(
        state.copyWith(
          buyerRiskDecisionStatus: CheckoutResourceStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to evaluate buyer risk.',
          ),
        ),
      );
      rethrow;
    }
  }

  void clearBuyerRiskDecisionState({bool resetStatus = true}) {
    emit(
      state.copyWith(
        buyerRiskDecisionStatus: resetStatus
            ? CheckoutResourceStatus.initial
            : state.buyerRiskDecisionStatus,
        clearBuyerRiskDecision: true,
        clearError: true,
      ),
    );
  }

  Future<Map<String, dynamic>> previewSupplierSplit({
    required int userId,
    required int siteId,
    required List<Map<String, dynamic>> lines,
    Map<String, dynamic>? draft,
    List<Map<String, dynamic>> supplierHints = const <Map<String, dynamic>>[],
  }) async {
    emit(
      state.copyWith(
        supplierSplitPreviewStatus: CheckoutResourceStatus.loading,
        clearError: true,
      ),
    );
    try {
      final preview = await _repository.previewSupplierSplit(
        userId: userId,
        siteId: siteId,
        lines: lines,
        draft: draft,
        supplierHints: supplierHints,
      );
      emit(
        state.copyWith(
          supplierSplitPreviewStatus: CheckoutResourceStatus.success,
          supplierSplitPreview: preview,
          clearError: true,
        ),
      );
      return preview;
    } catch (error) {
      emit(
        state.copyWith(
          supplierSplitPreviewStatus: CheckoutResourceStatus.failure,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to preview supplier grouping.',
          ),
        ),
      );
      rethrow;
    }
  }

  void clearSupplierSplitPreviewState({bool resetStatus = true}) {
    emit(
      state.copyWith(
        supplierSplitPreviewStatus: resetStatus
            ? CheckoutResourceStatus.initial
            : state.supplierSplitPreviewStatus,
        clearSupplierSplitPreview: true,
        clearError: true,
      ),
    );
  }

  Future<void> applyVoucher({
    required int siteId,
    required String code,
    required double quantity,
    required double total,
    required double delivery,
    required List<Map<String, dynamic>> products,
    int? userId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final voucher = await _repository.checkVoucher(
        siteId: siteId,
        code: code.trim(),
        quantity: quantity,
        total: total,
        delivery: delivery,
        products: products,
        userId: userId,
      );
      emit(
        state.copyWith(
          isLoading: false,
          voucherCode: code.trim(),
          voucher: voucher,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          voucherCode: '',
          clearVoucher: true,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to apply voucher.',
          ),
        ),
      );
    }
  }

  void clearVoucher() {
    emit(state.copyWith(voucherCode: '', clearVoucher: true, clearError: true));
  }

  Future<OrderCreateRes> makeOrder(
    OrderCreateReq model, {
    required bool isAuthenticated,
    int? userId,
    int? customerId,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _repository.makeOrder(
        model,
        isAuthenticated: isAuthenticated,
        userId: userId,
        customerId: customerId,
      );
      emit(
        state.copyWith(
          orderCreateResData: result,
          isLoading: false,
          clearError: true,
        ),
      );
      return result;
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Could not create order.',
          ),
        ),
      );
      rethrow;
    }
  }

  Future<PaymentGatewayResponse> paymentGatewayRequest(
    PaymentGatewayReq model,
  ) {
    return _repository.paymentGatewayRequest(model);
  }

  Future<PaymentResponse> payWithBkash(
    BuildContext context,
    double amount,
  ) async {
    try {
      final flutterBkash = FlutterBkash(
        bkashCredentials: BkashCredentials(
          username: PaymentConfig.BKASH_USERNAME.trim(),
          password: PaymentConfig.BKASH_PASSWORD.trim(),
          appKey: PaymentConfig.BKASH_APP_KEY.trim(),
          appSecret: PaymentConfig.BKASH_APP_SECRET.trim(),
          isSandbox: false,
        ),
      );

      final result = await flutterBkash.pay(
        context: context,
        amount: amount,
        merchantInvoiceNumber: 'INV${DateTime.now().millisecondsSinceEpoch}',
        payerReference: 'Ref-${DateTime.now().millisecondsSinceEpoch}',
      );
      log('bkash response: $result');

      if (result.paymentId.isNotEmpty && result.trxId.isNotEmpty) {
        return PaymentResponse(
          success: true,
          message: 'Payment Successful',
          amount: amount,
          paymentMethod: 'Bkash',
          transactionId: result.trxId,
        );
      }
      return PaymentResponse(
        success: false,
        message: 'Payment Failed or Cancelled',
        amount: amount,
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Bkash payment failed.',
          ),
        ),
      );
      return PaymentResponse(
        success: false,
        message: 'Error: $error',
        amount: amount,
      );
    }
  }
}
