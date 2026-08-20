import 'package:sellhub/core/bloc/safe_cubit.dart';
import 'package:sellhub/core/errors/app_failure.dart';
import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/profile/data/profile_repository.dart';
import 'package:sellhub/features/profile/data/model/store_customer_address.dart';
import 'package:sellhub/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends SafeCubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  void setIndexProfileItem(int index) {
    emit(state.copyWith(indexProfileItem: index));
  }

  set indexOrderItem(int index) {
    emit(state.copyWith(indexOrderItem: index));
  }

  Future<void> hydrateSession({required int siteId}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final isLoggedIn = await LocalStorage.isLogin();
      if (!isLoggedIn) {
        emit(
          state.copyWith(
            isLoading: false,
            isHydrated: true,
            isAuthenticated: false,
            profile: null,
            selfStoreCustomerRes: null,
            shippingAddresses: const <StoreCustomerAddressModel>[],
            billingAddresses: const <StoreCustomerAddressModel>[],
            clearError: true,
          ),
        );
        return;
      }

      final userId = await LocalStorage.getUserID() ?? 0;
      final customerId = await LocalStorage.getCustomerID() ?? 0;
      final customer = await _repository.fetchSelfStoreCustomer(userId, siteId);
      final profile = customerId > 0
          ? await _repository.fetchProfileDetails(customerId)
          : null;
      await LocalStorage.saveCustomerID(customer?.id ?? customerId);
      emit(
        state.copyWith(
          isLoading: false,
          isHydrated: true,
          isAuthenticated: true,
          profile: profile,
          selfStoreCustomerRes: customer,
          shippingAddresses:
              customer?.shippingAddress ?? const <StoreCustomerAddressModel>[],
          billingAddresses:
              customer?.billingAddress ?? const <StoreCustomerAddressModel>[],
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          isHydrated: true,
          isAuthenticated: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load profile session.',
          ),
        ),
      );
    }
  }

  Future<void> fetchProfileDetails(int id) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final profile = await _repository.fetchProfileDetails(id);
      emit(state.copyWith(profile: profile, isLoading: false));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load profile.',
          ),
        ),
      );
    }
  }

  Future<void> fetchOrderHistory(int siteId, int customerId) async {
    try {
      final data = await _repository.fetchOrderHistory(siteId, customerId);
      emit(state.copyWith(orderHistory: data, clearError: true));
    } catch (error) {
      emit(
        state.copyWith(
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to load orders.',
          ),
        ),
      );
    }
  }

  Future<void> fetchResellerInformation(int id) async {
    final data = await _repository.fetchResellerInformation(id);
    emit(state.copyWith(resellerResModelProfile: data));
  }

  Future<bool> makeResellerRequest(
    int userId,
    int customerId,
    String title,
    String paymentTitle,
    String paymentNo,
  ) {
    return _repository.makeResellerRequest(
      userId,
      customerId,
      title,
      paymentTitle,
      paymentNo,
    );
  }

  Future<void> fetchSelfStoreCustomer(int userId, int siteId) async {
    final data = await _repository.fetchSelfStoreCustomer(userId, siteId);
    await LocalStorage.saveCustomerID(data?.id ?? 0);
    emit(
      state.copyWith(
        selfStoreCustomerRes: data,
        shippingAddresses:
            data?.shippingAddress ?? const <StoreCustomerAddressModel>[],
        billingAddresses:
            data?.billingAddress ?? const <StoreCustomerAddressModel>[],
      ),
    );
  }

  Future<void> refreshAddressBook({required int siteId}) async {
    final userId = await LocalStorage.getUserID() ?? 0;
    if (userId <= 0) return;
    await fetchSelfStoreCustomer(userId, siteId);
  }

  Future<bool> addShippingAddress({
    required int siteId,
    required StoreCustomerAddressModel address,
  }) async {
    final customerId =
        state.selfStoreCustomerRes?.id ??
        await LocalStorage.getCustomerID() ??
        0;
    if (customerId <= 0) return false;
    emit(state.copyWith(addressActionInFlight: true, clearError: true));
    try {
      final ok = await _repository.addShippingAddress(
        customerId: customerId,
        address: address,
      );
      if (ok) {
        await refreshAddressBook(siteId: siteId);
      }
      emit(state.copyWith(addressActionInFlight: false, clearError: true));
      return ok;
    } catch (error) {
      emit(
        state.copyWith(
          addressActionInFlight: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to save shipping address.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> addBillingAddress({
    required int siteId,
    required StoreCustomerAddressModel address,
  }) async {
    final customerId =
        state.selfStoreCustomerRes?.id ??
        await LocalStorage.getCustomerID() ??
        0;
    if (customerId <= 0) return false;
    emit(state.copyWith(addressActionInFlight: true, clearError: true));
    try {
      final ok = await _repository.addBillingAddress(
        customerId: customerId,
        address: address,
      );
      if (ok) {
        await refreshAddressBook(siteId: siteId);
      }
      emit(state.copyWith(addressActionInFlight: false, clearError: true));
      return ok;
    } catch (error) {
      emit(
        state.copyWith(
          addressActionInFlight: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to save billing address.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> removeShippingAddress({
    required int siteId,
    required StoreCustomerAddressModel address,
  }) async {
    final customerId =
        state.selfStoreCustomerRes?.id ??
        await LocalStorage.getCustomerID() ??
        0;
    if (customerId <= 0) return false;
    emit(state.copyWith(addressActionInFlight: true, clearError: true));
    try {
      final ok = await _repository.removeShippingAddress(
        customerId: customerId,
        address: address,
      );
      if (ok) {
        await refreshAddressBook(siteId: siteId);
      }
      emit(state.copyWith(addressActionInFlight: false, clearError: true));
      return ok;
    } catch (error) {
      emit(
        state.copyWith(
          addressActionInFlight: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to remove shipping address.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> removeBillingAddress({
    required int siteId,
    required StoreCustomerAddressModel address,
  }) async {
    final customerId =
        state.selfStoreCustomerRes?.id ??
        await LocalStorage.getCustomerID() ??
        0;
    if (customerId <= 0) return false;
    emit(state.copyWith(addressActionInFlight: true, clearError: true));
    try {
      final ok = await _repository.removeBillingAddress(
        customerId: customerId,
        address: address,
      );
      if (ok) {
        await refreshAddressBook(siteId: siteId);
      }
      emit(state.copyWith(addressActionInFlight: false, clearError: true));
      return ok;
    } catch (error) {
      emit(
        state.copyWith(
          addressActionInFlight: false,
          error: AppFailure.fromObject(
            error,
            fallbackTitle: 'Unable to remove billing address.',
          ),
        ),
      );
      return false;
    }
  }

  Future<bool> passwordChange(int id, String oldPassword, String newPassword) {
    return _repository.passwordChange(id, oldPassword, newPassword);
  }
}
