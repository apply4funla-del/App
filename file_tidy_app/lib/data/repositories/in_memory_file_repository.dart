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
          createdAt: DateTime.now(),
        ),
      );
      return;
    }
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
}
