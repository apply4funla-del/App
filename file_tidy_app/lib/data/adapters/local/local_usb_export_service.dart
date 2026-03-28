import 'dart:io';

import 'package:file_tidy_app/core/interfaces/usb_export_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class LocalUsbExportService implements UsbExportService {
  @override
  Future<int> exportFiles({
    required List<FileItem> files,
    required String destinationFolderPath,
  }) async {
    final destination = Directory(destinationFolderPath);
    if (!destination.existsSync()) {
      return 0;
    }

    var copied = 0;
    for (final item in files) {
      final path = item.path;
      if (path == null) {
        continue;
      }
      final source = File(path);
      if (!source.existsSync()) {
        continue;
      }

      final targetPath = _nextAvailablePath(
        parentPath: destination.path,
        fileName: item.name,
      );
      try {
        await source.copy(targetPath);
        copied += 1;
      } catch (_) {
        // Skip failed file and continue.
      }
    }

    return copied;
  }

  String _nextAvailablePath({
    required String parentPath,
    required String fileName,
  }) {
    final requested = '$parentPath${Platform.pathSeparator}$fileName';
    final requestedFile = File(requested);
    if (!requestedFile.existsSync()) {
      return requested;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final base = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';

    var suffix = 1;
    while (true) {
      final candidate =
          '$parentPath${Platform.pathSeparator}${base}_copy$suffix$extension';
      if (!File(candidate).existsSync()) {
        return candidate;
      }
      suffix += 1;
    }
  }
}
