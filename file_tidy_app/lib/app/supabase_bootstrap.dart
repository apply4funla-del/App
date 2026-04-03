import 'package:file_tidy_app/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static final SupabaseConfig _config = const SupabaseConfig.fromEnvironment();
  static bool _initialized = false;

  static SupabaseConfig get config => _config;

  static Future<void> initializeIfConfigured() async {
    if (_initialized || !_config.isConfigured) {
      return;
    }
    await Supabase.initialize(
      url: _config.url,
      anonKey: _config.anonKey,
    );
    _initialized = true;
  }
}
