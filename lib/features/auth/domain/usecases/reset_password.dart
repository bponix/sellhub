import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class ResetPassword {
  const ResetPassword(this._repository);

  final AuthRepositoryContract _repository;

  Future<User?> call({
    required int userId,
    required String phone,
    required int otp,
    required String newPassword,
  }) {
    return _repository.resetPassword(userId, phone, otp, newPassword);
  }
}
