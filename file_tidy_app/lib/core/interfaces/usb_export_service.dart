import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict_resolution.dart';
import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';

abstract class UsbExportService {
  Future<List<UsbArchiveConflict>> detectConflicts({
    required List<FileItem> files,
    required String destinationFolderPath,
  });

  Future<UsbArchiveExecutionResult> exportFiles({
    required List<FileItem> files,
    required String destinationFolderPath,
    required UsbArchiveConflictResolution conflictResolution,
  });
}
