import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

abstract class LocalFilePickerService {
  Future<List<FileItem>> pickFiles();

  Future<LocalFolderImportResult?> pickFolderItems();
}
