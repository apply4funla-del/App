import 'package:file_tidy_app/core/models/file_item.dart';

abstract class UsbExportService {
  Future<int> exportFiles({
    required List<FileItem> files,
    required String destinationFolderPath,
  });
}
