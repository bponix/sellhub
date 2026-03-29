import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class CheckUser {
  const CheckUser(this._repository);

  final AuthRepositoryContract _repository;

  Future<User?> call(String phone) => _repository.checkUser(phone);
}
