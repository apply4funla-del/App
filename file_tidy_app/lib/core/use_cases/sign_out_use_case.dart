import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AppAuthRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}
