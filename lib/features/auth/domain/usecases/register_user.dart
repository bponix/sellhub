import 'package:sellhub/features/auth/data/models/sign_up_req.dart';
import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class RegisterUser {
  const RegisterUser(this._repository);

  final AuthRepositoryContract _repository;

  Future<User?> call(SignUpReq model) => _repository.register(model);
}
