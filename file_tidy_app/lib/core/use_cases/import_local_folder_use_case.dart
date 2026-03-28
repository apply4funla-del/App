import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class ImportLocalFolderUseCase {
  const ImportLocalFolderUseCase(
    this._picker,
    this._repository,
  );

  final LocalFilePickerService _picker;
  final FileRepository _repository;

  Future<List<FileItem>> call() async {
    final files = await _picker.pickFolderItems();
    if (files.isEmpty) {
      return [];
    }
    await _repository.addItems(source: FileSource.phone, items: files);
    return files;
  }
}
