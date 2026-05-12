import 'package:sellhub/core/local_seed/sellhub_commerce_local_store.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart' as auth_model;

class SellHubLocalAuthStore {
  SellHubLocalAuthStore(this._commerceStore);

  final SellHubCommerceLocalStore _commerceStore;

  Future<auth_model.User?> checkUser(String phone) =>
      _commerceStore.checkUser(phone);

  Future<String> login(String id, String password) =>
      _commerceStore.login(id, password);

  Future<auth_model.User?> register(SignUpReq model) =>
      _commerceStore.register(model);

  Future<auth_model.User?> sendOtp(int userId, String source, int sourceId) =>
      _commerceStore.sendOtp(userId, source, sourceId);

  Future<auth_model.User?> verifyOtp(int userId, int otp) =>
      _commerceStore.verifyOtp(userId, otp);

  Future<auth_model.User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) => _commerceStore.resetPassword(userId, phone, otp, newPassword);
}
