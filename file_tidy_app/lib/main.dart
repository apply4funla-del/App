import 'package:file_tidy_app/app/supabase_bootstrap.dart';
import 'package:file_tidy_app/app/app_shell.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initializeIfConfigured();
  runApp(const AppShell());
}
