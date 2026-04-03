import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

class LocalFilePickerAdapter implements LocalFilePickerService {
  static const int _maxFolderImportCount = 5000;

  @override
  Future<String?> pickDirectoryPath() {
    return FilePicker.platform.getDirectoryPath();
  }

  @override
  Future<List<FileItem>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'txt',
        'md',
        'csv',
        'json',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'mp4',
        'mov',
      ],
    );

    if (result == null) {
      return [];
    }

    final files = <FileItem>[];
    for (final value in result.files) {
      final path = value.path;
      if (path == null) {
        continue;
      }

      files.add(_itemFromPath(path, files.length));
    }
    return files;
  }

  @override
  Future<LocalFolderImportResult?> pickFolderItems() async {
    final directoryPath = await pickDirectoryPath();
    if (directoryPath == null) {
      return null;
    }
    final normalizedRootPath = _normalizePath(directoryPath);

    final directory = Directory(normalizedRootPath);
    if (!directory.existsSync()) {
      return null;
    }

    final items = <FileItem>[];
    final seenFolderPaths = <String>{normalizedRootPath};
    var importedFileCount = 0;

    items.add(
      FileItem(
        id: 'folder_$normalizedRootPath',
        name: _folderDisplayName(normalizedRootPath),
        type: FileItemType.folder,
        source: FileSource.phone,
        path: normalizedRootPath,
        parentPath: _normalizePath(directory.parent.path),
      ),
    );

    try {
      final stream = directory.list(recursive: true, followLinks: false).handleError((_) {});
      await for (final entity in stream) {
        if (entity is Directory) {
          final normalizedDirectoryPath = _normalizePath(entity.path);
          if (seenFolderPaths.add(normalizedDirectoryPath)) {
            items.add(
              FileItem(
                id: 'folder_$normalizedDirectoryPath',
                name: _folderDisplayName(normalizedDirectoryPath),
                type: FileItemType.folder,
                source: FileSource.phone,
                path: normalizedDirectoryPath,
                parentPath: _normalizePath(entity.parent.path),
              ),
            );
          }
          continue;
        }

        if (entity is File && importedFileCount < _maxFolderImportCount) {
          items.add(_itemFromPath(entity.path, items.length));
          importedFileCount += 1;
        }
      }
    } catch (_) {
      // Keep whatever was discovered and continue with partial tree.
    }

    return LocalFolderImportResult(
      rootPath: normalizedRootPath,
      files: items,
    );
  }

  FileItemType _resolveType(String name) {
    final extension = name.split('.').last.toLowerCase();
    if (extension == 'pdf') {
      return FileItemType.pdf;
    }
    if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(extension)) {
      return FileItemType.image;
    }
    if (['txt', 'md', 'csv', 'json', 'log'].contains(extension)) {
      return FileItemType.text;
    }
    return FileItemType.document;
  }

  FileItem _itemFromPath(String path, int index) {
    final normalizedPath = _normalizePath(path);
    final file = File(normalizedPath);
    final name = normalizedPath.split(Platform.pathSeparator).last;
    final exists = file.existsSync();
    return FileItem(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      type: _resolveType(name),
      source: FileSource.phone,
      path: normalizedPath,
      parentPath: _normalizePath(file.parent.path),
      modifiedAt: exists ? file.lastModifiedSync() : null,
      sizeBytes: exists ? file.lengthSync() : null,
    );
  }

  String _normalizePath(String value) {
    final separator = Platform.pathSeparator;
    var path = value.trim();
    while (path.length > 1 && path.endsWith(separator)) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  String _folderDisplayName(String path) {
    final separator = Platform.pathSeparator;
    final segments = path.split(separator).where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return path;
    }
    return segments.last;
  }
}
