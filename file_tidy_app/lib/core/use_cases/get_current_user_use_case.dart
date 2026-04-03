import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AppAuthRepository _repository;

  Future<AppUserSession?> call() {
    return _repository.getCurrentUser();
  }
}
