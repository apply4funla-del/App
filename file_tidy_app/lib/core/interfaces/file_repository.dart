import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/rename_record.dart';

abstract class FileRepository {
  Future<List<FileItem>> listItems(FileSource source);

  Future<void> renameFile({
    required String fileId,
    required String newName,
  });

  Future<List<RenameRecord>> listHistory();

  Future<void> undoRename(String recordId);
}
