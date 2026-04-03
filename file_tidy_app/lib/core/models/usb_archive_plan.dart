import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_preset_folder.dart';

class UsbArchivePlan {
  const UsbArchivePlan({
    required this.title,
    required this.sourceLabel,
    required this.sourceRootPath,
    required this.destinationFolderPath,
    required this.destinationLabel,
    required this.presetFolder,
    required this.files,
  });

  final String title;
  final String sourceLabel;
  final String sourceRootPath;
  final String destinationFolderPath;
  final String destinationLabel;
  final UsbArchivePresetFolder presetFolder;
  final List<FileItem> files;
}
