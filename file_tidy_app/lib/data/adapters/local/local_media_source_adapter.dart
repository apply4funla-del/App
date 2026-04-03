import 'dart:io';

import 'package:file_tidy_app/core/interfaces/media_source_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

class LocalMediaSourceAdapter implements MediaSourceService {
  static const int _maxPhotoImportCount = 5000;

  @override
  Future<LocalFolderImportResult?> loadPhotoLibrary() async {
    final roots = _candidateRoots();
    for (final root in roots) {
      final directory = Directory(root);
      if (!directory.existsSync()) {
        continue;
      }
      final result = await _scanPhotoFolder(directory);
      if (result != null && result.files.where((item) => item.type != FileItemType.folder).isNotEmpty) {
        return result;
      }
    }
    return null;
  }

  List<String> _candidateRoots() {
    if (Platform.isAndroid) {
      return const [
        '/storage/emulated/0/DCIM',
        '/sdcard/DCIM',
      ];
    }

    final userProfile = Platform.environment['USERPROFILE'];
    if (Platform.isWindows && userProfile != null && userProfile.isNotEmpty) {
      return [
        '$userProfile\\DCIM',
        '$userProfile\\Pictures\\DCIM',
        '$userProfile\\Pictures',
        '$userProfile\\OneDrive\\Pictures',
      ];
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      return [
        '$home/DCIM',
        '$home/Pictures',
      ];
    }

    return const [];
  }

  Future<LocalFolderImportResult?> _scanPhotoFolder(Directory root) async {
    final rootPath = _normalizePath(root.path);
    final items = <FileItem>[
      FileItem(
        id: 'folder_$rootPath',
        name: _folderDisplayName(rootPath),
        type: FileItemType.folder,
        source: FileSource.phone,
        path: rootPath,
        parentPath: _normalizePath(root.parent.path),
      ),
    ];
    final seenFolders = <String>{rootPath};
    var fileCount = 0;

    try {
      final stream = root.list(recursive: true, followLinks: false).handleError((_) {});
      await for (final entity in stream) {
        if (entity is Directory) {
          final normalizedPath = _normalizePath(entity.path);
          if (seenFolders.add(normalizedPath)) {
            items.add(
              FileItem(
                id: 'folder_$normalizedPath',
                name: _folderDisplayName(normalizedPath),
                type: FileItemType.folder,
                source: FileSource.phone,
                path: normalizedPath,
                parentPath: _normalizePath(entity.parent.path),
              ),
            );
          }
          continue;
        }

        if (entity is! File || fileCount >= _maxPhotoImportCount) {
          continue;
        }

        final name = entity.uri.pathSegments.isEmpty ? entity.path : entity.uri.pathSegments.last;
        if (!_isMediaName(name)) {
          continue;
        }

        items.add(_itemFromPath(entity.path, items.length));
        fileCount += 1;
      }
    } catch (_) {
      // Partial result is still usable.
    }

    return LocalFolderImportResult(rootPath: rootPath, files: items);
  }

  bool _isMediaName(String name) {
    final extension = name.split('.').last.toLowerCase();
    return const {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
      'mp4',
      'mov',
      'm4v',
      'avi',
      'mkv',
      '3gp',
    }.contains(extension);
  }

  FileItem _itemFromPath(String path, int index) {
    final normalizedPath = _normalizePath(path);
    final file = File(normalizedPath);
    final name = normalizedPath.split(Platform.pathSeparator).last;
    final extension = name.split('.').last.toLowerCase();
    final type = switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' || 'heif' => FileItemType.image,
      _ => FileItemType.document,
    };

    return FileItem(
      id: 'photo_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      type: type,
      source: FileSource.phone,
      path: normalizedPath,
      parentPath: _normalizePath(file.parent.path),
      modifiedAt: file.existsSync() ? file.lastModifiedSync() : null,
      sizeBytes: file.existsSync() ? file.lengthSync() : null,
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
    final segments = path.split(Platform.pathSeparator).where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return path;
    }
    return segments.last;
  }
}
