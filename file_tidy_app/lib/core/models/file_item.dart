enum FileItemType { folder, pdf, image, text, document }

enum FileSource { phone, googleDrive, dropbox }

class FileItem {
  const FileItem({
    required this.id,
    required this.name,
    required this.type,
    required this.source,
    this.path,
    this.parentPath = '/',
    this.duplicateOfFileId,
    this.modifiedAt,
  });

  final String id;
  final String name;
  final FileItemType type;
  final FileSource source;
  final String? path;
  final String parentPath;
  final String? duplicateOfFileId;
  final DateTime? modifiedAt;

  FileItem copyWith({
    String? name,
    String? path,
    String? parentPath,
    String? duplicateOfFileId,
    bool clearDuplicateOfFileId = false,
    DateTime? modifiedAt,
  }) {
    return FileItem(
      id: id,
      name: name ?? this.name,
      type: type,
      source: source,
      path: path ?? this.path,
      parentPath: parentPath ?? this.parentPath,
      duplicateOfFileId: clearDuplicateOfFileId ? null : (duplicateOfFileId ?? this.duplicateOfFileId),
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }
}

extension FileSourceLabel on FileSource {
  String get label {
    switch (this) {
      case FileSource.phone:
        return 'Phone';
      case FileSource.googleDrive:
        return 'Google Drive';
      case FileSource.dropbox:
        return 'Dropbox';
    }
  }
}
