import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepositoryContract _repository;

  Future<User?> call({required int userId, required int otp}) {
    return _repository.verifyOtp(userId, otp);
  }
}
