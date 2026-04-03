import 'package:file_tidy_app/core/models/app_user_session.dart';

abstract class AppAuthRepository {
  bool get isConfigured;

  Future<AppUserSession?> getCurrentUser();

  Future<AppUserSession> signIn({
    required String email,
    required String password,
  });

  Future<AppUserSession> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
