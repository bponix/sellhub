import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class LoginUser {
  const LoginUser(this._repository);

  final AuthRepositoryContract _repository;

  Future<String> call({required String userId, required String password}) {
    return _repository.login(userId, password);
  }
}
