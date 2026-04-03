import 'package:file_tidy_app/app/supabase_bootstrap.dart';
import 'package:file_tidy_app/core/interfaces/app_auth_repository.dart';
import 'package:file_tidy_app/core/interfaces/ai_rename_service.dart';
import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/interfaces/local_file_mutation_service.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/interfaces/media_source_service.dart';
import 'package:file_tidy_app/core/interfaces/storage_permission_service.dart';
import 'package:file_tidy_app/core/interfaces/subscription_repository.dart';
import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/interfaces/usb_storage_service.dart';
import 'package:file_tidy_app/data/adapters/ai/mock_ai_rename_service.dart';
import 'package:file_tidy_app/data/adapters/local/local_file_mutation_adapter.dart';
import 'package:file_tidy_app/data/adapters/local/local_file_picker_adapter.dart';
import 'package:file_tidy_app/data/adapters/local/local_media_source_adapter.dart';
import 'package:file_tidy_app/data/adapters/local/permission_handler_storage_permission_adapter.dart';
import 'package:file_tidy_app/data/adapters/local/local_usb_export_service.dart';
import 'package:file_tidy_app/data/adapters/local/local_usb_storage_adapter.dart';
import 'package:file_tidy_app/data/repositories/local/local_app_auth_repository.dart';
import 'package:file_tidy_app/data/repositories/local/local_subscription_repository.dart';
import 'package:file_tidy_app/data/repositories/in_memory_file_repository.dart';
import 'package:file_tidy_app/data/repositories/shared_prefs_connector_auth_repository.dart';
import 'package:file_tidy_app/data/repositories/supabase/supabase_app_auth_repository.dart';
import 'package:file_tidy_app/data/repositories/supabase/supabase_subscription_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DependencyContainer {
  DependencyContainer._();

  static final DependencyContainer instance = DependencyContainer._();

  late final SupabaseClient? _supabaseClient = _buildSupabaseClient();

  final FileRepository fileRepository = InMemoryFileRepository();
  final AiRenameService aiRenameService = MockAiRenameService();
  final LocalFilePickerService localFilePickerService = LocalFilePickerAdapter();
  final LocalFileMutationService localFileMutationService = LocalFileMutationAdapter();
  final MediaSourceService mediaSourceService = LocalMediaSourceAdapter();
  final StoragePermissionService storagePermissionService =
      PermissionHandlerStoragePermissionAdapter();
  final UsbExportService usbExportService = LocalUsbExportService();
  final UsbStorageService usbStorageService = LocalUsbStorageAdapter();
  final ConnectorAuthRepository connectorAuthRepository = SharedPrefsConnectorAuthRepository();
  late final AppAuthRepository appAuthRepository = _buildAppAuthRepository();
  late final SubscriptionRepository subscriptionRepository = _buildSubscriptionRepository();

  SupabaseClient? _buildSupabaseClient() {
    if (!SupabaseBootstrap.config.isConfigured) {
      return null;
    }
    return Supabase.instance.client;
  }

  AppAuthRepository _buildAppAuthRepository() {
    final client = _supabaseClient;
    if (client == null) {
      return const LocalAppAuthRepository();
    }
    return SupabaseAppAuthRepository(client);
  }

  SubscriptionRepository _buildSubscriptionRepository() {
    final client = _supabaseClient;
    if (client == null) {
      return const LocalSubscriptionRepository();
    }
    return SupabaseSubscriptionRepository(client);
  }
}
