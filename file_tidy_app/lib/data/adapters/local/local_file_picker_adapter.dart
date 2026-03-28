import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

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
  Future<List<FileItem>> pickFolderItems() async {
    final directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath == null) {
      return [];
    }

    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      return [];
    }

    final items = <FileItem>[];
    final entities = directory.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      if (items.length >= _maxFolderImportCount) {
        break;
      }
      items.add(_itemFromPath(entity.path, items.length));
    }
    return items;
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
