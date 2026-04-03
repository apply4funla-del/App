import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';

class SignInWithEmailUseCase {
  const SignInWithEmailUseCase(this._repository);

  final AppAuthRepository _repository;

  Future<AppUserSession> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
