import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class ReplaceOriginalsWithDuplicatesUseCase {
  const ReplaceOriginalsWithDuplicatesUseCase(this._repository);

  final FileRepository _repository;

  Future<int> call({
    required FileSource source,
    required String parentPath,
  }) {
    return _repository.replaceOriginalsWithDuplicates(
      source: source,
      parentPath: parentPath,
    );
  }
}
