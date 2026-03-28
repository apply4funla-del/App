import 'package:file_tidy_app/core/interfaces/file_repository.dart';

class RenameFileUseCase {
  const RenameFileUseCase(this._repository);

  final FileRepository _repository;

  Future<void> call({
    required String fileId,
    required String newName,
  }) {
    return _repository.renameFile(fileId: fileId, newName: newName);
  }
}
