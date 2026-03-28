import 'package:file_tidy_app/core/models/file_item.dart';

abstract class LocalFilePickerService {
  Future<List<FileItem>> pickFiles();
}
