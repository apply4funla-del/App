import 'package:file_tidy_app/core/interfaces/media_source_service.dart';
import 'package:file_tidy_app/core/interfaces/usb_storage_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_plan.dart';
import 'package:file_tidy_app/core/models/usb_archive_preset_folder.dart';

class PreparePhotoArchiveUseCase {
  PreparePhotoArchiveUseCase(
    this._mediaSourceService,
    this._usbStorageService,
  );

  final MediaSourceService _mediaSourceService;
  final UsbStorageService _usbStorageService;

  Future<UsbArchivePlan?> call() async {
    final source = await _mediaSourceService.loadPhotoLibrary();
    if (source == null) {
      return null;
    }
    final destination = await _usbStorageService.ensurePresetFolder(
      presetFolder: UsbArchivePresetFolder.memoirsPhotos,
    );
    if (destination == null) {
      return null;
    }
    final files = source.files.where((item) => item.type != FileItemType.folder).toList();
    return UsbArchivePlan(
      title: 'Archive Photos',
      sourceLabel: 'Phone photo library',
      sourceRootPath: source.rootPath,
      destinationFolderPath: destination,
      destinationLabel: UsbArchivePresetFolder.memoirsPhotos.label,
      presetFolder: UsbArchivePresetFolder.memoirsPhotos,
      files: files,
    );
  }
}
