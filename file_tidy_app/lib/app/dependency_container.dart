import 'package:file_tidy_app/core/interfaces/ai_rename_service.dart';
import 'package:file_tidy_app/core/interfaces/connector_auth_repository.dart';
import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/data/adapters/ai/mock_ai_rename_service.dart';
import 'package:file_tidy_app/data/adapters/local/local_file_picker_adapter.dart';
import 'package:file_tidy_app/data/adapters/local/local_usb_export_service.dart';
import 'package:file_tidy_app/data/repositories/in_memory_file_repository.dart';
import 'package:file_tidy_app/data/repositories/shared_prefs_connector_auth_repository.dart';

class DependencyContainer {
  DependencyContainer._();

  static final DependencyContainer instance = DependencyContainer._();

  final FileRepository fileRepository = InMemoryFileRepository();
  final AiRenameService aiRenameService = MockAiRenameService();
  final LocalFilePickerService localFilePickerService = LocalFilePickerAdapter();
  final UsbExportService usbExportService = LocalUsbExportService();
  final ConnectorAuthRepository connectorAuthRepository = SharedPrefsConnectorAuthRepository();
}
