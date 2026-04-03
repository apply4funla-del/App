import 'package:file_tidy_app/core/models/usb_archive_preset_folder.dart';

abstract class UsbStorageService {
  Future<String?> findConnectedUsbRootPath();

  Future<String?> ensurePresetFolder({
    required UsbArchivePresetFolder presetFolder,
    String? childFolderName,
  });
}
