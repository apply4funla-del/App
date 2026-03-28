import 'package:file_tidy_app/core/models/file_item.dart';

class LocalFolderImportResult {
  const LocalFolderImportResult({
    required this.rootPath,
    required this.files,
  });

  final String rootPath;
  final List<FileItem> files;
}
