import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';

class LocalFilePickerAdapter implements LocalFilePickerService {
  static const int _maxFolderImportCount = 250;

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
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return null;
    }

    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return null;
    }

    final items = <FileItem>[];
    final seenFolderPaths = <String>{};
    var importedFileCount = 0;
    final pendingDirectories = <Directory>[directory];

    while (pendingDirectories.isNotEmpty && importedFileCount < _maxFolderImportCount) {
      final current = pendingDirectories.removeLast();
      if (seenFolderPaths.add(current.path)) {
        items.add(
          FileItem(
            id: 'folder_${current.path}',
            name: current.path.split(Platform.pathSeparator).last,
            type: FileItemType.folder,
            source: FileSource.phone,
            path: current.path,
            parentPath: current.parent.path,
          ),
        );
      }
      try {
        final entities = current.listSync(followLinks: false);
        for (final entity in entities) {
          if (importedFileCount >= _maxFolderImportCount) {
            break;
          }
          if (entity is File) {
            items.add(_itemFromPath(entity.path, items.length));
            importedFileCount += 1;
            continue;
          }
          if (entity is Directory) {
            if (seenFolderPaths.add(entity.path)) {
              items.add(
                FileItem(
                  id: 'folder_${entity.path}',
                  name: entity.path.split(Platform.pathSeparator).last,
                  type: FileItemType.folder,
                  source: FileSource.phone,
                  path: entity.path,
                  parentPath: entity.parent.path,
                ),
              );
            }
            pendingDirectories.add(entity);
          }
        }
      } catch (_) {
        // Skip restricted directory and continue scanning others.
      }
    }

    return LocalFolderImportResult(
      rootPath: directoryPath,
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
    final file = File(path);
    final name = path.split(Platform.pathSeparator).last;
    return FileItem(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      type: _resolveType(name),
      source: FileSource.phone,
      path: path,
      parentPath: file.parent.path,
      modifiedAt: file.existsSync() ? file.lastModifiedSync() : null,
    );
  }
}
