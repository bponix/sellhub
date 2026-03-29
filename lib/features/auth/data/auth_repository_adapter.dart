import 'package:sellhub/features/auth/data/auth_repository.dart' as remote;
import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class AuthRepositoryAdapter implements AuthRepositoryContract {
  AuthRepositoryAdapter(this._remote);

  final remote.AuthRepository _remote;

  @override
  Future<User?> checkUser(String phone) => _remote.checkUser(phone);

  @override
  Future<String> login(String id, String password) =>
      _remote.login(id, password);

  @override
  Future<User?> register(SignUpReq model) => _remote.register(model);

  @override
  Future<User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  ) => _remote.resetPassword(userId, phone, otp, newPassword);

  @override
  Future<User?> sendOtp(int userId, String source, int sourceId) {
    return _remote.sendOtp(userId, source, sourceId);
  }

  @override
  Future<User?> verifyOtp(int userId, int otp) =>
      _remote.verifyOtp(userId, otp);
}
