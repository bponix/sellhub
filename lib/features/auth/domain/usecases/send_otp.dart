import 'package:sellhub/features/auth/data/models/user_model.dart';
import 'package:sellhub/features/auth/domain/repositories/auth_repository_contract.dart';

class SendOtp {
  const SendOtp(this._repository);

  final AuthRepositoryContract _repository;

  Future<User?> call({
    required int userId,
    required String source,
    required int sourceId,
  }) {
    return _repository.sendOtp(userId, source, sourceId);
  }
}
