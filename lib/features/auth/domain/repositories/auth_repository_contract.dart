import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';

abstract class AuthRepositoryContract {
  Future<User?> checkUser(String phone);
  Future<String> login(String id, String password);
  Future<User?> register(SignUpReq model);
  Future<User?> sendOtp(int userId, String source, int sourceId);
  Future<User?> verifyOtp(int userId, int otp);
  Future<User?> resetPassword(
    int userId,
    String phone,
    int otp,
    String newPassword,
  );
}
