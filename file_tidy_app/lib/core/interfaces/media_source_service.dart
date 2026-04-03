import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

abstract class MediaSourceService {
  Future<LocalFolderImportResult?> loadPhotoLibrary();
}
