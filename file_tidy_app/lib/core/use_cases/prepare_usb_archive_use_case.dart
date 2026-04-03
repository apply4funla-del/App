import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict.dart';

class PrepareUsbArchiveUseCase {
  PrepareUsbArchiveUseCase(this._usbExportService);

  final UsbExportService _usbExportService;

  Future<List<UsbArchiveConflict>> call({
    required List<FileItem> files,
    required String destinationFolderPath,
  }) {
    return _usbExportService.detectConflicts(
      files: files,
      destinationFolderPath: destinationFolderPath,
    );
  }
}
