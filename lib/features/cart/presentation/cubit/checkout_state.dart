import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/voucher_check_res.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';

enum CheckoutResourceStatus { initial, loading, success, failure }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.deliveryCharge = 0,
    this.deliveryWay = '',
    this.logisticId = 0,
    this.gateWayText = '',
    this.areaSelect = 0,
    this.paySelect = 0,
    this.deliveryPlace = const <DeliveryPlaceRes>[],
    this.paymentMethod = const <PaymentMethodRes>[],
    this.orderCreateResData,
    this.customerId = 0,
    this.savedBillingAddresses = const <StoreCustomerAddressModel>[],
    this.savedShippingAddresses = const <StoreCustomerAddressModel>[],
    this.selectedShippingAddressId,
    this.voucherCode = '',
    this.voucher,
    this.quickOrderDraftStatus = CheckoutResourceStatus.initial,
    this.quickOrderDraft,
    this.buyerRiskDecisionStatus = CheckoutResourceStatus.initial,
    this.buyerRiskDecision,
    this.supplierSplitPreviewStatus = CheckoutResourceStatus.initial,
    this.supplierSplitPreview,
    this.isLoading = false,
    this.error,
  });

  final double deliveryCharge;
  final String deliveryWay;
  final int logisticId;
  final String gateWayText;
  final int areaSelect;
  final int paySelect;
  final List<DeliveryPlaceRes> deliveryPlace;
  final List<PaymentMethodRes> paymentMethod;
  final OrderCreateRes? orderCreateResData;
  final int customerId;
  final List<StoreCustomerAddressModel> savedBillingAddresses;
  final List<StoreCustomerAddressModel> savedShippingAddresses;
  final int? selectedShippingAddressId;
  final String voucherCode;
  final VoucherCheckRes? voucher;
  final CheckoutResourceStatus quickOrderDraftStatus;
  final Map<String, dynamic>? quickOrderDraft;
  final CheckoutResourceStatus buyerRiskDecisionStatus;
  final Map<String, dynamic>? buyerRiskDecision;
  final CheckoutResourceStatus supplierSplitPreviewStatus;
  final Map<String, dynamic>? supplierSplitPreview;
  final bool isLoading;
  final AppFailure? error;

  bool get hasResumableQuickOrderDraft {
    final draft = quickOrderDraft;
    if (draft == null) return false;
    final lines = draft['lines'];
    if (lines is List) return lines.isNotEmpty;
    return draft.isNotEmpty;
  }

  String? get buyerRiskDisposition =>
      buyerRiskDecision?['decision']?.toString();

  CheckoutResourceStatus get supplierOrderGroupingStatus =>
      supplierSplitPreviewStatus;

  Map<String, dynamic>? get supplierOrderGroupingPreview =>
      supplierSplitPreview;

  CheckoutState copyWith({
    double? deliveryCharge,
    String? deliveryWay,
    int? logisticId,
    String? gateWayText,
    int? areaSelect,
    int? paySelect,
    List<DeliveryPlaceRes>? deliveryPlace,
    List<PaymentMethodRes>? paymentMethod,
    OrderCreateRes? orderCreateResData,
    int? customerId,
    List<StoreCustomerAddressModel>? savedBillingAddresses,
    List<StoreCustomerAddressModel>? savedShippingAddresses,
    int? selectedShippingAddressId,
    bool clearSelectedShippingAddress = false,
    String? voucherCode,
    VoucherCheckRes? voucher,
    bool clearVoucher = false,
    CheckoutResourceStatus? quickOrderDraftStatus,
    Map<String, dynamic>? quickOrderDraft,
    bool clearQuickOrderDraft = false,
    CheckoutResourceStatus? buyerRiskDecisionStatus,
    Map<String, dynamic>? buyerRiskDecision,
    bool clearBuyerRiskDecision = false,
    CheckoutResourceStatus? supplierSplitPreviewStatus,
    Map<String, dynamic>? supplierSplitPreview,
    bool clearSupplierSplitPreview = false,
    bool? isLoading,
    AppFailure? error,
    bool clearError = false,
  }) {
    return CheckoutState(
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      deliveryWay: deliveryWay ?? this.deliveryWay,
      logisticId: logisticId ?? this.logisticId,
      gateWayText: gateWayText ?? this.gateWayText,
      areaSelect: areaSelect ?? this.areaSelect,
      paySelect: paySelect ?? this.paySelect,
      deliveryPlace: deliveryPlace ?? this.deliveryPlace,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderCreateResData: orderCreateResData ?? this.orderCreateResData,
      customerId: customerId ?? this.customerId,
      savedBillingAddresses:
          savedBillingAddresses ?? this.savedBillingAddresses,
      savedShippingAddresses:
          savedShippingAddresses ?? this.savedShippingAddresses,
      selectedShippingAddressId: clearSelectedShippingAddress
          ? null
          : selectedShippingAddressId ?? this.selectedShippingAddressId,
      voucherCode: voucherCode ?? this.voucherCode,
      voucher: clearVoucher ? null : voucher ?? this.voucher,
      quickOrderDraftStatus:
          quickOrderDraftStatus ?? this.quickOrderDraftStatus,
      quickOrderDraft: clearQuickOrderDraft
          ? null
          : quickOrderDraft ?? this.quickOrderDraft,
      buyerRiskDecisionStatus:
          buyerRiskDecisionStatus ?? this.buyerRiskDecisionStatus,
      buyerRiskDecision: clearBuyerRiskDecision
          ? null
          : buyerRiskDecision ?? this.buyerRiskDecision,
      supplierSplitPreviewStatus:
          supplierSplitPreviewStatus ?? this.supplierSplitPreviewStatus,
      supplierSplitPreview: clearSupplierSplitPreview
          ? null
          : supplierSplitPreview ?? this.supplierSplitPreview,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    deliveryCharge,
    deliveryWay,
    logisticId,
    gateWayText,
    areaSelect,
    paySelect,
    deliveryPlace,
    paymentMethod,
    orderCreateResData,
    customerId,
    savedBillingAddresses,
    savedShippingAddresses,
    selectedShippingAddressId,
    voucherCode,
    voucher,
    quickOrderDraftStatus,
    quickOrderDraft,
    buyerRiskDecisionStatus,
    buyerRiskDecision,
    supplierSplitPreviewStatus,
    supplierSplitPreview,
    isLoading,
    error,
  ];
}
