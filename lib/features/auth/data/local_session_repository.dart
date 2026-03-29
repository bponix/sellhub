import 'package:sellhub/core/local/local_storage.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/session_repository.dart';

class LocalSessionRepository implements SessionRepository {
  @override
  Future<void> clear() => LocalStorage.clearSession();

  @override
  Future<bool> isLoggedIn() => LocalStorage.isLogin();

  @override
  Future<void> saveSession({required User user, required String token}) async {
    await LocalStorage.saveUserID(user.id);
    await LocalStorage.saveToken(token);
    await LocalStorage.setLogin(true);
    await LocalStorage.setGuest(false);
  }

  @override
  Future<String?> getToken() => LocalStorage.getToken();

  @override
  Future<int?> getUserId() => LocalStorage.getUserID();
}
