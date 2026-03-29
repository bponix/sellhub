import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/cart/data/models/delivery_place_res.dart';
import 'package:sellhub/features/cart/data/models/order_create_res.dart';
import 'package:sellhub/features/cart/data/models/payment_method_res.dart';
import 'package:sellhub/features/cart/data/models/voucher_check_res.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';

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
  final bool isLoading;
  final AppFailure? error;

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
    isLoading,
    error,
  ];
}
