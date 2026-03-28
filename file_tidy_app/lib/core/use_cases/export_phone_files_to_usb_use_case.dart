import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class ExportPhoneFilesToUsbUseCase {
  const ExportPhoneFilesToUsbUseCase(
    this._repository,
    this._usbExportService,
  );

  final FileRepository _repository;
  final UsbExportService _usbExportService;

  Future<int> call({
    required String destinationFolderPath,
  }) async {
    final items = await _repository.listItems(FileSource.phone);
    final files = items
        .where((item) => item.type != FileItemType.folder && item.path != null)
        .toList();

    return _usbExportService.exportFiles(
      files: files,
      destinationFolderPath: destinationFolderPath,
    );
  }
}
