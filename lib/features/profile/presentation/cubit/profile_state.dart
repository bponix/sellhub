import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:equatable/equatable.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/features/profile/data/model/order_res_model.dart';
import 'package:sellhub/features/profile/data/model/profile_res-Model.dart';
import 'package:sellhub/features/profile/data/model/reseller_response_model.dart';
import 'package:sellhub/features/profile/data/model/self_store_customer.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.profile,
    this.orderHistory = const <OrderHistoryResModelProfile>[],
    this.resellerResModelProfile,
    this.selfStoreCustomerRes,
    this.shippingAddresses = const <StoreCustomerAddressModel>[],
    this.billingAddresses = const <StoreCustomerAddressModel>[],
    this.indexProfileItem = 0,
    this.indexOrderItem = 0,
    this.isLoading = false,
    this.isHydrated = false,
    this.isAuthenticated = false,
    this.addressActionInFlight = false,
    this.error,
  });

  final ProfileResModel? profile;
  final List<OrderHistoryResModelProfile> orderHistory;
  final ResellerResModelProfile? resellerResModelProfile;
  final SelfStoreCustomerRes? selfStoreCustomerRes;
  final List<StoreCustomerAddressModel> shippingAddresses;
  final List<StoreCustomerAddressModel> billingAddresses;
  final int indexProfileItem;
  final int indexOrderItem;
  final bool isLoading;
  final bool isHydrated;
  final bool isAuthenticated;
  final bool addressActionInFlight;
  final AppFailure? error;

  ProfileState copyWith({
    ProfileResModel? profile,
    List<OrderHistoryResModelProfile>? orderHistory,
    ResellerResModelProfile? resellerResModelProfile,
    SelfStoreCustomerRes? selfStoreCustomerRes,
    List<StoreCustomerAddressModel>? shippingAddresses,
    List<StoreCustomerAddressModel>? billingAddresses,
    int? indexProfileItem,
    int? indexOrderItem,
    bool? isLoading,
    bool? isHydrated,
    bool? isAuthenticated,
    bool? addressActionInFlight,
    AppFailure? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      orderHistory: orderHistory ?? this.orderHistory,
      resellerResModelProfile:
          resellerResModelProfile ?? this.resellerResModelProfile,
      selfStoreCustomerRes: selfStoreCustomerRes ?? this.selfStoreCustomerRes,
      shippingAddresses: shippingAddresses ?? this.shippingAddresses,
      billingAddresses: billingAddresses ?? this.billingAddresses,
      indexProfileItem: indexProfileItem ?? this.indexProfileItem,
      indexOrderItem: indexOrderItem ?? this.indexOrderItem,
      isLoading: isLoading ?? this.isLoading,
      isHydrated: isHydrated ?? this.isHydrated,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      addressActionInFlight:
          addressActionInFlight ?? this.addressActionInFlight,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    orderHistory,
    resellerResModelProfile,
    selfStoreCustomerRes,
    shippingAddresses,
    billingAddresses,
    indexProfileItem,
    indexOrderItem,
    isLoading,
    isHydrated,
    isAuthenticated,
    addressActionInFlight,
    error,
  ];
}
