import 'package:sellhub/features/auth/domain/repositories/session_repository.dart';

class LogoutUser {
  const LogoutUser(this._repository);

  final SessionRepository _repository;

  Future<void> call() => _repository.clear();
}
