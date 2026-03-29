import 'dart:io';

import 'package:file_tidy_app/core/interfaces/file_repository.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/rename_record.dart';

class InMemoryFileRepository implements FileRepository {
  InMemoryFileRepository();

  final List<RenameRecord> _history = [];

  final Map<FileSource, List<FileItem>> _store = {
    FileSource.phone: [],
    FileSource.googleDrive: [
      FileItem(
        id: 'g1',
        name: 'Invoices',
        type: FileItemType.folder,
        source: FileSource.googleDrive,
      ),
      FileItem(
        id: 'g2',
        name: 'Client_Statement_03-2026.pdf',
        type: FileItemType.pdf,
        source: FileSource.googleDrive,
      ),
      FileItem(
        id: 'g3',
        name: 'Trip_Album_March.jpg',
        type: FileItemType.image,
        source: FileSource.googleDrive,
      ),
    ],
    FileSource.dropbox: [
      FileItem(
        id: 'd1',
        name: 'Receipts',
        type: FileItemType.folder,
        source: FileSource.dropbox,
      ),
      FileItem(
        id: 'd2',
        name: 'Old_Contract_final_v2.pdf',
        type: FileItemType.pdf,
        source: FileSource.dropbox,
      ),
      FileItem(
        id: 'd3',
        name: 'Vacation_2024_9981.png',
        type: FileItemType.image,
        source: FileSource.dropbox,
      ),
    ],
  };

  @override
  Future<List<FileItem>> listItems(FileSource source) async {
    return List<FileItem>.unmodifiable(_store[source] ?? []);
  }

  @override
  Future<void> addItems({
    required FileSource source,
    required List<FileItem> items,
  }) async {
    if (items.isEmpty) {
      return;
    }
    if (source == FileSource.phone) {
      _store[source] = [...items];
      return;
    }
    _store[source] = [...(_store[source] ?? []), ...items];
  }

  @override
  Future<void> renameFile({
    required String fileId,
    required String newName,
  }) async {
    for (final entry in _store.entries) {
      final index = entry.value.indexWhere((item) => item.id == fileId);
      if (index < 0) {
        continue;
      }

      final original = entry.value[index];
      String? nextPath = original.path;
      if (original.path != null) {
        final currentFile = File(original.path!);
        if (currentFile.existsSync()) {
          final renamedPath = '${currentFile.parent.path}${Platform.pathSeparator}$newName';
          try {
            final renamed = await currentFile.rename(renamedPath);
            nextPath = renamed.path;
          } catch (_) {
            nextPath = original.path;
          }
        }
      }

      entry.value[index] = original.copyWith(
        name: newName,
        path: nextPath,
        modifiedAt: DateTime.now(),
      );
      _history.insert(
        0,
        RenameRecord(
          id: '${fileId}_${DateTime.now().microsecondsSinceEpoch}',
          fileId: fileId,
          beforeName: original.name,
          afterName: newName,
          beforePath: original.path,
          afterPath: nextPath,
          sourceFileId: original.duplicateOfFileId,
          actionType: RenameActionType.renameInPlace,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
  }

  @override
  Future<void> duplicateFile({
    required String fileId,
    required String newName,
  }) async {
    for (final entry in _store.entries) {
      final index = entry.value.indexWhere((item) => item.id == fileId);
      if (index < 0) {
        continue;
      }

      final source = entry.value[index];
      final duplicateId = 'dup_${DateTime.now().microsecondsSinceEpoch}';
      var duplicatePath = source.path;

      if (source.path != null) {
        final sourceFile = File(source.path!);
        if (sourceFile.existsSync()) {
          final rawTargetPath = '${sourceFile.parent.path}${Platform.pathSeparator}$newName';
          final targetPath = _nextAvailablePath(rawTargetPath);
          try {
            final copied = await sourceFile.copy(targetPath);
            duplicatePath = copied.path;
          } catch (_) {
            duplicatePath = source.path;
          }
        }
      }

      final duplicateItem = FileItem(
        id: duplicateId,
        name: newName,
        type: source.type,
        source: source.source,
        path: duplicatePath,
        parentPath: source.parentPath,
        duplicateOfFileId: source.id,
        modifiedAt: DateTime.now(),
      );
      entry.value.insert(index + 1, duplicateItem);

      _history.insert(
        0,
        RenameRecord(
          id: '${duplicateId}_${DateTime.now().microsecondsSinceEpoch}',
          fileId: duplicateId,
          sourceFileId: source.id,
          beforeName: source.name,
          afterName: newName,
          beforePath: source.path,
          afterPath: duplicatePath,
          actionType: RenameActionType.duplicateCreated,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
  }

  @override
  Future<int> replaceOriginalsWithDuplicates({
    required FileSource source,
    required String parentPath,
  }) async {
    final items = _store[source];
    if (items == null || items.isEmpty) {
      return 0;
    }

    final duplicates = items
        .where((item) => item.parentPath == parentPath && item.duplicateOfFileId != null)
        .toList();

    var replaced = 0;
    for (final duplicate in duplicates) {
      final sourceId = duplicate.duplicateOfFileId;
      if (sourceId == null) {
        continue;
      }
      final duplicateIndex = items.indexWhere((item) => item.id == duplicate.id);
      final originalIndex = items.indexWhere((item) => item.id == sourceId);
      if (duplicateIndex < 0 || originalIndex < 0) {
        continue;
      }

      final original = items[originalIndex];
      if (original.path != null) {
        final originalFile = File(original.path!);
        if (originalFile.existsSync()) {
          try {
            await originalFile.delete();
          } catch (_) {
            // Keep moving; in-memory entry will still be replaced.
          }
        }
      }

      items.removeAt(originalIndex);
      var normalizedIndex = duplicateIndex;
      if (originalIndex < duplicateIndex) {
        normalizedIndex -= 1;
      }
      final normalizedDuplicate = items[normalizedIndex].copyWith(
        clearDuplicateOfFileId: true,
        modifiedAt: DateTime.now(),
      );
      items[normalizedIndex] = normalizedDuplicate;

      _history.insert(
        0,
        RenameRecord(
          id: 'replace_${normalizedDuplicate.id}_${DateTime.now().microsecondsSinceEpoch}',
          fileId: normalizedDuplicate.id,
          sourceFileId: sourceId,
          beforeName: original.name,
          afterName: normalizedDuplicate.name,
          beforePath: original.path,
          afterPath: normalizedDuplicate.path,
          actionType: RenameActionType.replaceWithDuplicate,
          createdAt: DateTime.now(),
        ),
      );
      replaced += 1;
    }

    return replaced;
  }

  @override
  Future<List<RenameRecord>> listHistory() async {
    return List<RenameRecord>.unmodifiable(_history);
  }

  @override
  Future<void> undoRename(String recordId) async {
    final recordIndex = _history.indexWhere((record) => record.id == recordId);
    if (recordIndex < 0) {
      return;
    }

    final record = _history[recordIndex];
    if (record.actionType == RenameActionType.duplicateCreated) {
      for (final entry in _store.entries) {
        final index = entry.value.indexWhere((item) => item.id == record.fileId);
        if (index < 0) {
          continue;
        }
        final duplicate = entry.value[index];
        if (duplicate.path != null) {
          final duplicateFile = File(duplicate.path!);
          if (duplicateFile.existsSync()) {
            try {
              await duplicateFile.delete();
            } catch (_) {
              // Keep in-memory undo behavior even if filesystem delete fails.
            }
          }
        }
        entry.value.removeAt(index);
        _history.removeAt(recordIndex);
        return;
      }
    }

    if (record.actionType == RenameActionType.replaceWithDuplicate) {
      _history.removeAt(recordIndex);
      return;
    }

    for (final entry in _store.entries) {
      final index = entry.value.indexWhere((item) => item.id == record.fileId);
      if (index < 0) {
        continue;
      }

      final original = entry.value[index];
      String? nextPath = original.path;
      if (original.path != null) {
        final currentFile = File(original.path!);
        if (currentFile.existsSync()) {
          final renamedPath = '${currentFile.parent.path}${Platform.pathSeparator}${record.beforeName}';
          try {
            final renamed = await currentFile.rename(renamedPath);
            nextPath = renamed.path;
          } catch (_) {
            nextPath = record.beforePath ?? original.path;
          }
        }
      }

      entry.value[index] = original.copyWith(
        name: record.beforeName,
        path: nextPath,
        modifiedAt: DateTime.now(),
      );
      _history.removeAt(recordIndex);
      return;
    }
  }

  String _nextAvailablePath(String requestedPath) {
    final requestedFile = File(requestedPath);
    if (!requestedFile.existsSync()) {
      return requestedPath;
    }
    final parent = requestedFile.parent.path;
    final name = requestedFile.uri.pathSegments.last;
    final dotIndex = name.lastIndexOf('.');
    final base = dotIndex > 0 ? name.substring(0, dotIndex) : name;
    final extension = dotIndex > 0 ? name.substring(dotIndex) : '';

    var suffix = 1;
    while (true) {
      final candidate =
          '$parent${Platform.pathSeparator}${base}_copy$suffix$extension';
      if (!File(candidate).existsSync()) {
        return candidate;
      }
      suffix += 1;
    }
  }
}
