import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/rename_operation_mode.dart';

class ExplorerLaunchConfig {
  const ExplorerLaunchConfig({
    required this.source,
    required this.operationMode,
    this.requestFolderOnStart = false,
    this.initialPhoneRootPath,
  });

  final FileSource source;
  final RenameOperationMode operationMode;
  final bool requestFolderOnStart;
  final String? initialPhoneRootPath;
}
