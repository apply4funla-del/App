import 'package:file_tidy_app/core/interfaces/file_repository.dart';

class DuplicateFileUseCase {
  const DuplicateFileUseCase(this._repository);

  final FileRepository _repository;

  Future<void> call({
    required String fileId,
    required String newName,
  }) {
    return _repository.duplicateFile(fileId: fileId, newName: newName);
  }
}
