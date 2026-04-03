import 'dart:io';

import 'package:file_tidy_app/core/interfaces/usb_storage_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';
import 'package:file_tidy_app/core/models/usb_archive_plan.dart';
import 'package:file_tidy_app/core/models/usb_archive_preset_folder.dart';

class PrepareFolderArchiveUseCase {
  PrepareFolderArchiveUseCase(this._usbStorageService);

  final UsbStorageService _usbStorageService;

  Future<UsbArchivePlan?> call(LocalFolderImportResult source) async {
    final rootName = _folderDisplayName(source.rootPath);
    final destination = await _usbStorageService.ensurePresetFolder(
      presetFolder: UsbArchivePresetFolder.memoirsFolders,
      childFolderName: rootName,
    );
    if (destination == null) {
      return null;
    }
    final files = source.files.where((item) => item.type != FileItemType.folder).toList();
    return UsbArchivePlan(
      title: 'Archive Specific Folder',
      sourceLabel: rootName,
      sourceRootPath: source.rootPath,
      destinationFolderPath: destination,
      destinationLabel: '${UsbArchivePresetFolder.memoirsFolders.label} / $rootName',
      presetFolder: UsbArchivePresetFolder.memoirsFolders,
      files: files,
    );
  }

  String _folderDisplayName(String path) {
    final segments = path.split(Platform.pathSeparator).where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return path;
    }
    return segments.last;
  }
}
