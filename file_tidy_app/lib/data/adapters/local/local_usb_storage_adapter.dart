import 'dart:io';

import 'package:file_tidy_app/core/interfaces/usb_storage_service.dart';
import 'package:file_tidy_app/core/models/usb_archive_preset_folder.dart';

class LocalUsbStorageAdapter implements UsbStorageService {
  @override
  Future<String?> findConnectedUsbRootPath() async {
    if (Platform.isWindows) {
      return _findWindowsUsbRoot();
    }
    return null;
  }

  @override
  Future<String?> ensurePresetFolder({
    required UsbArchivePresetFolder presetFolder,
    String? childFolderName,
  }) async {
    final root = await findConnectedUsbRootPath();
    if (root == null) {
      return null;
    }

    var currentPath = root;
    for (final segment in presetFolder.pathSegments) {
      currentPath = '$currentPath${Platform.pathSeparator}$segment';
      Directory(currentPath).createSync(recursive: true);
    }
    if (childFolderName != null && childFolderName.trim().isNotEmpty) {
      currentPath = '$currentPath${Platform.pathSeparator}${_sanitizeSegment(childFolderName)}';
      Directory(currentPath).createSync(recursive: true);
    }
    return currentPath;
  }

  String? _findWindowsUsbRoot() {
    final systemDrive = (Platform.environment['SystemDrive'] ?? 'C:').toUpperCase();
    String? fallback;

    for (var codeUnit = 'D'.codeUnitAt(0); codeUnit <= 'Z'.codeUnitAt(0); codeUnit++) {
      final letter = String.fromCharCode(codeUnit);
      final rootPath = '$letter:\\';
      if ('$letter:' == systemDrive) {
        continue;
      }
      final directory = Directory(rootPath);
      if (!directory.existsSync()) {
        continue;
      }

      final memoirsFolder = Directory('$rootPath${Platform.pathSeparator}Memoirs');
      if (memoirsFolder.existsSync()) {
        return rootPath;
      }

      fallback ??= rootPath;
    }
    return fallback;
  }

  String _sanitizeSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    return sanitized.isEmpty ? 'Archive' : sanitized;
  }
}
