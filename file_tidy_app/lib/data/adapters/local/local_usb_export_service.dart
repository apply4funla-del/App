import 'dart:io';

import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict_resolution.dart';
import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';

class LocalUsbExportService implements UsbExportService {
  @override
  Future<List<UsbArchiveConflict>> detectConflicts({
    required List<FileItem> files,
    required String destinationFolderPath,
  }) async {
    final destination = Directory(destinationFolderPath);
    if (!destination.existsSync()) {
      return const [];
    }

    final conflicts = <UsbArchiveConflict>[];
    for (final item in files) {
      final sourcePath = item.path;
      if (sourcePath == null) {
        continue;
      }
      final requested = File('$destinationFolderPath${Platform.pathSeparator}${item.name}');
      if (!requested.existsSync()) {
        continue;
      }
      conflicts.add(
        UsbArchiveConflict(
          sourceName: item.name,
          existingPath: requested.path,
          suggestedName: _nextAvailableName(
            parentPath: destinationFolderPath,
            fileName: item.name,
          ),
        ),
      );
    }
    return conflicts;
  }

  @override
  Future<UsbArchiveExecutionResult> exportFiles({
    required List<FileItem> files,
    required String destinationFolderPath,
    required UsbArchiveConflictResolution conflictResolution,
  }) async {
    final destination = Directory(destinationFolderPath);
    if (!destination.existsSync()) {
      return const UsbArchiveExecutionResult(fileResults: []);
    }

    final results = <UsbArchiveFileResult>[];
    for (final item in files) {
      final sourcePath = item.path;
      if (sourcePath == null) {
        continue;
      }
      final source = File(sourcePath);
      if (!source.existsSync()) {
        results.add(
          UsbArchiveFileResult(
            fileId: item.id,
            fileName: item.name,
            sourcePath: sourcePath,
            destinationPath: '',
            outcome: UsbArchiveFileOutcome.failed,
            verified: false,
          ),
        );
        continue;
      }

      final requestedPath = '$destinationFolderPath${Platform.pathSeparator}${item.name}';
      final requestedTarget = File(requestedPath);

      late final String targetPath;
      late final UsbArchiveFileOutcome outcome;
      if (requestedTarget.existsSync()) {
        if (conflictResolution == UsbArchiveConflictResolution.replaceExisting) {
          try {
            await requestedTarget.delete();
          } catch (_) {}
          targetPath = requestedPath;
          outcome = UsbArchiveFileOutcome.replacedExisting;
        } else {
          targetPath = '$destinationFolderPath${Platform.pathSeparator}${_nextAvailableName(parentPath: destinationFolderPath, fileName: item.name)}';
          outcome = UsbArchiveFileOutcome.renamedCopy;
        }
      } else {
        targetPath = requestedPath;
        outcome = UsbArchiveFileOutcome.copied;
      }

      try {
        final copiedFile = await source.copy(targetPath);
        final verified = copiedFile.existsSync() && copiedFile.lengthSync() == source.lengthSync();
        results.add(
          UsbArchiveFileResult(
            fileId: item.id,
            fileName: copiedFile.uri.pathSegments.last,
            sourcePath: sourcePath,
            destinationPath: copiedFile.path,
            outcome: outcome,
            verified: verified,
          ),
        );
      } catch (_) {
        results.add(
          UsbArchiveFileResult(
            fileId: item.id,
            fileName: item.name,
            sourcePath: sourcePath,
            destinationPath: targetPath,
            outcome: UsbArchiveFileOutcome.failed,
            verified: false,
          ),
        );
      }
    }

    return UsbArchiveExecutionResult(fileResults: results);
  }

  String _nextAvailableName({
    required String parentPath,
    required String fileName,
  }) {
    final requested = '$parentPath${Platform.pathSeparator}$fileName';
    final requestedFile = File(requested);
    if (!requestedFile.existsSync()) {
      return fileName;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';

    var suffix = 1;
    while (true) {
      final candidateName = '$base - $suffix$extension';
      final candidatePath = '$parentPath${Platform.pathSeparator}$candidateName';
      if (!File(candidatePath).existsSync()) {
        return candidateName;
      }
      suffix += 1;
    }
  }
}
