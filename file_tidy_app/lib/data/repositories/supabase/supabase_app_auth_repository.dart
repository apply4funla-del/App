import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';
import 'package:file_tidy_app/core/models/app_user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAppAuthRepository implements AppAuthRepository {
  SupabaseAppAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get isConfigured => true;

  @override
  Future<AppUserSession?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    return AppUserSession(
      userId: user.id,
      email: user.email ?? '',
    );
  }

  @override
  Future<AppUserSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to sign in.');
    }
    return AppUserSession(
      userId: user.id,
      email: user.email ?? email,
    );
  }

  @override
  Future<AppUserSession> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw const AuthException('Unable to create account.');
    }
    return AppUserSession(
      userId: user.id,
      email: user.email ?? email,
    );
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
