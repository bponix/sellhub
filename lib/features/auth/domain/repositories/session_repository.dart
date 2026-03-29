import 'package:sellhub/features/auth/data/models/user_model.dart';

abstract class SessionRepository {
  Future<void> saveSession({required User user, required String token});

  Future<void> clear();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<int?> getUserId();
}
