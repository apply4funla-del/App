import 'package:file_tidy_app/core/interfaces/local_file_mutation_service.dart';
import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict_resolution.dart';
import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';
import 'package:file_tidy_app/core/models/usb_archive_retention_mode.dart';

class ExecuteUsbArchiveUseCase {
  ExecuteUsbArchiveUseCase(
    this._usbExportService,
    this._localFileMutationService,
  );

  final UsbExportService _usbExportService;
  final LocalFileMutationService _localFileMutationService;

  Future<UsbArchiveExecutionResult> call({
    required List<FileItem> files,
    required String destinationFolderPath,
    required UsbArchiveConflictResolution conflictResolution,
    required UsbArchiveRetentionMode retentionMode,
  }) async {
    final result = await _usbExportService.exportFiles(
      files: files,
      destinationFolderPath: destinationFolderPath,
      conflictResolution: conflictResolution,
    );

    if (retentionMode != UsbArchiveRetentionMode.removeFromPhone) {
      return result;
    }

    final removablePaths = result.fileResults
        .where((item) => item.verified && item.outcome != UsbArchiveFileOutcome.failed)
        .map((item) => item.sourcePath)
        .toSet()
        .toList();
    final deletedCount = await _localFileMutationService.deleteFiles(removablePaths);
    return result.copyWith(removedOriginalCount: deletedCount);
  }
}
