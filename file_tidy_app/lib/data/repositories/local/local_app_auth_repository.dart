import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';

class LocalAppAuthRepository implements AppAuthRepository {
  const LocalAppAuthRepository();

  @override
  bool get isConfigured => false;

  @override
  Future<AppUserSession?> getCurrentUser() async => null;

  @override
  Future<AppUserSession> signIn({
    required String email,
    required String password,
  }) {
    throw StateError('Supabase sign-in is not configured yet.');
  }

  @override
  Future<AppUserSession> signUp({
    required String email,
    required String password,
  }) {
    throw StateError('Supabase sign-in is not configured yet.');
  }

  @override
  Future<void> signOut() async {}
}
