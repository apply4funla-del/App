import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/interfaces/storage_permission_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

class ImportLocalFolderUseCase {
  const ImportLocalFolderUseCase(
    this._picker,
    this._repository,
    this._storagePermissionService,
  );

  final LocalFilePickerService _picker;
  final FileRepository _repository;
  final StoragePermissionService _storagePermissionService;

  Future<LocalFolderImportResult?> call() async {
    final hasPermission = await _storagePermissionService.ensurePhoneReadAccess();
    if (!hasPermission) {
      return null;
    }
    final result = await _picker.pickFolderItems();
    if (result == null || result.files.isEmpty) {
      return result;
    }
    await _repository.addItems(source: FileSource.phone, items: result.files);
    return result;
  }
}
