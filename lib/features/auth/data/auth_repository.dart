import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/core/local_seed/sellhub_local_auth_store.dart';
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';

class AuthRepository {
  AuthRepository(Object? client, this._localAuthStore);

  final SellHubLocalAuthStore _localAuthStore;

  Future<String> login(String id, String password) async {
    final token = await _localAuthStore.login(id, password);
    if (token.isNotEmpty) {
      await LocalStorage.saveToken(token);
    }
    return token;
  }

  Future<User?> register(SignUpReq model) => _localAuthStore.register(model);

  Future<User?> checkUser(String phone) => _localAuthStore.checkUser(phone);

  Future<User?> sendOtp(int userId, String source, int sourceId) =>
      _localAuthStore.sendOtp(userId, source, sourceId);

  Future<User?> verifyOtp(int userId, int otp) =>
      _localAuthStore.verifyOtp(userId, otp);

  Future<User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) => _localAuthStore.resetPassword(userId, phone, otp, newPassword);
}
