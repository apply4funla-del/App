import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_tidy_app/core/interfaces/local_file_picker_service.dart';
import 'package:file_tidy_app/core/models/file_item.dart';

class LocalFilePickerAdapter implements LocalFilePickerService {
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

      final file = File(path);
      files.add(
        FileItem(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}_${files.length}',
          name: value.name,
          type: _resolveType(value.name),
          source: FileSource.phone,
          path: path,
          parentPath: file.parent.path,
          modifiedAt: file.existsSync() ? file.lastModifiedSync() : null,
        ),
      );
    }
    return files;
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
}
