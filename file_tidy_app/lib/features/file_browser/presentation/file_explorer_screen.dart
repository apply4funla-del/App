import 'dart:io';

import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/config/feature_flags.dart';
import 'package:file_tidy_app/core/models/explorer_launch_config.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';
import 'package:file_tidy_app/core/models/rename_operation_mode.dart';
import 'package:file_tidy_app/core/use_cases/duplicate_file_use_case.dart';
import 'package:file_tidy_app/core/use_cases/get_ai_rename_suggestions_use_case.dart';
import 'package:file_tidy_app/core/use_cases/import_local_folder_use_case.dart';
import 'package:file_tidy_app/core/use_cases/replace_originals_with_duplicates_use_case.dart';
import 'package:file_tidy_app/core/use_cases/rename_file_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:file_tidy_app/features/preview/presentation/preview_pane.dart';
import 'package:file_tidy_app/features/rename_manual/presentation/rename_sheet.dart';
import 'package:flutter/material.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({
    super.key,
    required this.config,
  });

  final ExplorerLaunchConfig config;

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final _dependencies = DependencyContainer.instance;

  late final RenameFileUseCase _renameFileUseCase;
  late final DuplicateFileUseCase _duplicateFileUseCase;
  late final ReplaceOriginalsWithDuplicatesUseCase _replaceOriginalsWithDuplicatesUseCase;
  late final GetAiRenameSuggestionsUseCase _getAiRenameSuggestionsUseCase;
  late final ImportLocalFolderUseCase _importLocalFolderUseCase;

  FileSource _currentSource = FileSource.phone;
  RenameOperationMode _operationMode = RenameOperationMode.workInPlace;

  FileItem? _focusedItem;
  FileItem? _previewItem;
  List<FileItem> _items = [];
  bool _loading = false;
  bool _requestedFolderOnStart = false;

  String? _phoneRootPath;
  String? _phoneCurrentPath;
  bool _phoneFolderBrowsingEnabled = false;

  List<FileItem> get _currentPhoneEntries {
    if (!_phoneFolderBrowsingEnabled || _phoneCurrentPath == null) {
      final values = [..._items];
      values.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return values;
    }
    return _visiblePhoneEntries();
  }

  @override
  void initState() {
    super.initState();
    _renameFileUseCase = RenameFileUseCase(_dependencies.fileRepository);
    _duplicateFileUseCase = DuplicateFileUseCase(_dependencies.fileRepository);
    _replaceOriginalsWithDuplicatesUseCase = ReplaceOriginalsWithDuplicatesUseCase(
      _dependencies.fileRepository,
    );
    _getAiRenameSuggestionsUseCase = GetAiRenameSuggestionsUseCase(
      _dependencies.aiRenameService,
    );
    _importLocalFolderUseCase = ImportLocalFolderUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
    );

    _currentSource = widget.config.source;
    _operationMode = widget.config.operationMode;
    _phoneFolderBrowsingEnabled = _currentSource == FileSource.phone;
    if (_currentSource == FileSource.phone && widget.config.initialPhoneRootPath != null) {
      _phoneRootPath = widget.config.initialPhoneRootPath;
      _phoneCurrentPath = widget.config.initialPhoneRootPath;
    }
    _loadItems();

    if (widget.config.requestFolderOnStart && _currentSource == FileSource.phone) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _requestedFolderOnStart) {
          return;
        }
        _requestedFolderOnStart = true;
        await _importLocalFolder();
      });
    }
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final values = await _dependencies.fileRepository.listItems(_currentSource);
    if (!mounted) {
      return;
    }

    setState(() {
      _items = values;
      if (_currentSource == FileSource.phone) {
        if (_phoneFolderBrowsingEnabled) {
          _syncPhoneNavigation(values);
        } else {
          _focusedItem = values.where((item) => item.type != FileItemType.folder).firstOrNull;
          _previewItem = _focusedItem;
        }
      } else {
        _focusedItem = values.where((item) => item.type != FileItemType.folder).firstOrNull;
        _previewItem = _focusedItem;
      }
      _loading = false;
    });
  }

  void _syncPhoneNavigation(List<FileItem> values) {
    if (values.isEmpty) {
      _phoneRootPath = null;
      _phoneCurrentPath = null;
      _focusedItem = null;
      _previewItem = null;
      return;
    }

    _phoneRootPath ??= _deriveCommonRootPath(values);
    _phoneCurrentPath ??= _phoneRootPath;
    _phoneCurrentPath ??= _phoneRootPath;

    final visible = _visiblePhoneEntries();
    if (visible.isEmpty) {
      _focusedItem = null;
      _previewItem = null;
      return;
    }

    _focusedItem ??= visible.first;
    if (_previewItem == null || _previewItem!.type == FileItemType.folder) {
      _previewItem = visible.firstWhere(
        (item) => item.type != FileItemType.folder,
        orElse: () => visible.first,
      );
    }
  }

  Future<void> _importLocalFolder() async {
    if (_currentSource != FileSource.phone) {
      return;
    }

    final result = await _tryImportLocalFolder();
    if (!mounted) {
      return;
    }
    if (result == null || !_hasBrowsableEntries(result)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a folder to amend the content.')),
      );
      return;
    }

    _phoneRootPath = result.rootPath;
    _phoneCurrentPath = result.rootPath;
    _phoneFolderBrowsingEnabled = true;
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loaded ${result.files.length} file(s) from folder.')),
    );
  }

  Future<LocalFolderImportResult?> _tryImportLocalFolder() async {
    try {
      return await _importLocalFolderUseCase();
    } catch (_) {
      if (!mounted) {
        return null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a folder to amend the content.')),
      );
      return null;
    }
  }

  Future<void> _openRenameSheet(FileItem item) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RenameSheet(
        currentName: item.name,
        confirmLabel: _operationMode == RenameOperationMode.workInPlace
            ? 'Confirm rename'
            : 'Create duplicate',
        suggestionsLoader: () => _getAiRenameSuggestionsUseCase(
          currentName: item.name,
          context: item.type.name,
        ),
      ),
    );

    if (value == null || value.isEmpty || value == item.name) {
      return;
    }
    await _applyRenameChange(item: item, newName: value);
  }

  Future<void> _applyRenameChange({
    required FileItem item,
    required String newName,
  }) async {
    if (_operationMode == RenameOperationMode.workInPlace) {
      await _renameFileUseCase(fileId: item.id, newName: newName);
      await _loadItems();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed to "$newName"')),
      );
      return;
    }

    await _duplicateFileUseCase(fileId: item.id, newName: newName);
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicate created as "$newName"')),
    );
  }

  Future<void> _replaceCurrentFolderOriginals() async {
    if (_currentSource != FileSource.phone || _phoneCurrentPath == null) {
      return;
    }
    final replaced = await _replaceOriginalsWithDuplicatesUseCase(
      source: _currentSource,
      parentPath: _phoneCurrentPath!,
    );
    await _loadItems();
    if (!mounted) {
      return;
    }
    final text = replaced == 0
        ? 'No duplicate pairs found in this folder.'
        : 'Replaced $replaced original file(s) with duplicates.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openItemInSplit(FileItem item) async {
    if (_currentSource == FileSource.phone && item.type == FileItemType.folder) {
      await _navigateIntoFolder(item.path ?? _phoneCurrentPath ?? '');
      return;
    }
    setState(() {
      _focusedItem = item;
      _previewItem = item;
    });
  }

  Future<void> _navigateIntoFolder(String folderPath) async {
    if (_currentSource != FileSource.phone || !_phoneFolderBrowsingEnabled) {
      return;
    }
    setState(() {
      _phoneCurrentPath = folderPath;
      _focusedItem = null;
      _previewItem = null;
      final visible = _visiblePhoneEntries();
      if (visible.isNotEmpty) {
        _focusedItem = visible.first;
      }
    });
    await _hydratePhoneFolderBranchIfNeeded(folderPath);
    if (!mounted) {
      return;
    }
    setState(() {
      final visible = _visiblePhoneEntries();
      if (visible.isNotEmpty && _focusedItem == null) {
        _focusedItem = visible.first;
      }
    });
  }

  void _goUpOneFolder() {
    if (_currentSource != FileSource.phone ||
        !_phoneFolderBrowsingEnabled ||
        _phoneCurrentPath == null ||
        _phoneRootPath == null ||
        _phoneCurrentPath == _phoneRootPath) {
      return;
    }
    final separator = Platform.pathSeparator;
    final current = _phoneCurrentPath!;
    final parent = current.substring(0, current.lastIndexOf(separator));
    setState(() {
      _phoneCurrentPath = parent;
      _focusedItem = null;
      _previewItem = null;
      final visible = _visiblePhoneEntries();
      if (visible.isNotEmpty) {
        _focusedItem = visible.first;
      }
    });
  }

  List<FileItem> _visiblePhoneEntries() {
    final current = _phoneCurrentPath;
    if (current == null) {
      return [];
    }

    final separator = Platform.pathSeparator;
    final normalizedCurrentPath = _normalizePath(current);
    final normalizedCurrent = '$normalizedCurrentPath$separator';
    final folderMap = <String, FileItem>{};
    final files = <FileItem>[];

    for (final item in _items) {
      if (item.path == null) {
        continue;
      }
      final path = _normalizePath(item.path!);
      final parentPath = _normalizePath(item.parentPath);
      if (path == normalizedCurrentPath) {
        continue;
      }
      if (!path.startsWith(normalizedCurrent) && parentPath != normalizedCurrentPath) {
        continue;
      }

      if (parentPath == normalizedCurrentPath) {
        if (item.type == FileItemType.folder) {
          folderMap[path] = item.copyWith(path: path, parentPath: parentPath);
        } else {
          files.add(item.copyWith(path: path, parentPath: parentPath));
        }
        continue;
      }

      final remainder = path.substring(normalizedCurrent.length);
      if (remainder.isEmpty) {
        continue;
      }
      if (!remainder.contains(separator)) {
        if (item.type == FileItemType.folder) {
          folderMap[path] = item.copyWith(name: remainder);
        } else {
          files.add(item.copyWith(name: remainder));
        }
        continue;
      }
      final firstSegment = remainder.split(separator).first;
      final folderPath = '$current$separator$firstSegment';
      folderMap.putIfAbsent(
        folderPath,
        () => FileItem(
          id: 'folder_$folderPath',
          name: firstSegment,
          type: FileItemType.folder,
          source: FileSource.phone,
          path: folderPath,
          parentPath: current,
        ),
      );
    }

    final folderItems = folderMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...folderItems, ...files];
  }

  Future<void> _hydratePhoneFolderBranchIfNeeded(String folderPath) async {
    if (_currentSource != FileSource.phone) {
      return;
    }
    final normalizedFolderPath = _normalizePath(folderPath);
    final separator = Platform.pathSeparator;
    final normalizedPrefix = '$normalizedFolderPath$separator';
    final alreadyLoaded = _items.any((item) {
      final path = item.path;
      if (path == null) {
        return false;
      }
      final normalizedPath = _normalizePath(path);
      final normalizedParent = _normalizePath(item.parentPath);
      return normalizedParent == normalizedFolderPath ||
          (normalizedPath != normalizedFolderPath && normalizedPath.startsWith(normalizedPrefix));
    });

    if (alreadyLoaded) {
      return;
    }

    final directory = Directory(normalizedFolderPath);
    if (!directory.existsSync()) {
      return;
    }

    final loaded = <FileItem>[];
    try {
      final entities = directory.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is Directory) {
          final normalizedPath = _normalizePath(entity.path);
          loaded.add(
            FileItem(
              id: 'folder_$normalizedPath',
              name: _folderDisplayName(normalizedPath),
              type: FileItemType.folder,
              source: FileSource.phone,
              path: normalizedPath,
              parentPath: normalizedFolderPath,
            ),
          );
          continue;
        }
        if (entity is File) {
          loaded.add(_fileItemFromDisk(entity.path, loaded.length));
        }
      }
    } catch (_) {
      return;
    }

    if (loaded.isEmpty || !mounted) {
      return;
    }

    setState(() {
      final existingPaths = _items
          .map((item) => item.path == null ? null : _normalizePath(item.path!))
          .whereType<String>()
          .toSet();
      final merged = <FileItem>[..._items];
      for (final item in loaded) {
        final path = item.path;
        if (path == null) {
          continue;
        }
        final normalizedPath = _normalizePath(path);
        if (existingPaths.contains(normalizedPath)) {
          continue;
        }
        existingPaths.add(normalizedPath);
        merged.add(item);
      }
      _items = merged;
    });
  }

  bool _hasBrowsableEntries(LocalFolderImportResult result) {
    final separator = Platform.pathSeparator;
    final root = _normalizePath(result.rootPath);
    final normalizedRoot = '$root$separator';

    for (final item in result.files) {
      final path = item.path;
      if (path == null) {
        continue;
      }
      final normalizedPath = _normalizePath(path);
      final normalizedParent = _normalizePath(item.parentPath);
      if (normalizedPath == root) {
        continue;
      }
      if (normalizedParent == root || normalizedPath.startsWith(normalizedRoot)) {
        return true;
      }
    }
    return false;
  }

  String _normalizePath(String value) {
    final separator = Platform.pathSeparator;
    var path = value.trim();
    while (path.length > 1 && path.endsWith(separator)) {
      path = path.substring(0, path.length - 1);
    }
    return path;
  }

  FileItem _fileItemFromDisk(String rawPath, int index) {
    final normalizedPath = _normalizePath(rawPath);
    final file = File(normalizedPath);
    final name = normalizedPath.split(Platform.pathSeparator).last;
    return FileItem(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      type: _resolveType(name),
      source: FileSource.phone,
      path: normalizedPath,
      parentPath: _normalizePath(file.parent.path),
      modifiedAt: file.existsSync() ? file.lastModifiedSync() : null,
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

  String _folderDisplayName(String path) {
    final separator = Platform.pathSeparator;
    final segments = path.split(separator).where((segment) => segment.isNotEmpty).toList();
    if (segments.isEmpty) {
      return path;
    }
    return segments.last;
  }

  String _deriveCommonRootPath(List<FileItem> items) {
    final paths = items.map((item) => item.path).whereType<String>().toList();
    if (paths.isEmpty) {
      return '';
    }
    final separator = Platform.pathSeparator;
    final splitPaths = paths.map((path) => path.split(separator)).toList();
    final first = splitPaths.first;
    var matchLength = first.length;
    for (final parts in splitPaths.skip(1)) {
      var i = 0;
      while (i < matchLength && i < parts.length && parts[i] == first[i]) {
        i++;
      }
      matchLength = i;
    }
    if (matchLength == 0) {
      return Directory(paths.first).parent.path;
    }
    return first.take(matchLength).join(separator);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (FeatureFlags.enableUsbArchive)
            IconButton(
              icon: const Icon(Icons.usb_outlined),
              tooltip: 'USB archive',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.usbArchive),
            ),
          if (_currentSource == FileSource.phone)
            IconButton(
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: 'Choose folder',
              onPressed: _importLocalFolder,
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: DropdownButton<FileSource>(
              value: _currentSource,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                setState(() {
                  _currentSource = value;
                  _focusedItem = null;
                  _previewItem = null;
                  if (value == FileSource.phone) {
                    _phoneFolderBrowsingEnabled = true;
                  } else {
                    _phoneCurrentPath = null;
                    _phoneRootPath = null;
                    _phoneFolderBrowsingEnabled = false;
                  }
                });
                await _loadItems();
              },
              items: FileSource.values
                  .map(
                    (source) => DropdownMenuItem<FileSource>(
                      value: source,
                      child: Text(source.label),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildSplitExplorer(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'History',
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Privacy',
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: 'Settings',
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      label: 'History',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppButton.secondary(
                      label: 'Privacy',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppButton.primary(
                      label: 'Settings',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSplitExplorer() {
    final entries = _currentSource == FileSource.phone ? _currentPhoneEntries : _items;

    final leftPanel = Column(
      children: [
        if (_currentSource == FileSource.phone && _phoneCurrentPath != null)
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(
              _phoneCurrentPath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _phoneRootPath == _phoneCurrentPath
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _goUpOneFolder,
                  ),
          ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    _currentSource == FileSource.phone && _phoneCurrentPath != null
                        ? 'This folder has no readable files.'
                        : 'Pick a folder to amend the content.',
                  ),
                )
              : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final item = entries[index];
                      final selected = _focusedItem?.id == item.id;
                      return ListTile(
                        selected: selected,
                        leading: _iconFor(item.type),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _openItemInSplit(item),
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    final rightPanel = Column(
      children: [
        Expanded(
          child: PreviewPane(item: _previewItem),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final renameLabel = _operationMode == RenameOperationMode.workInPlace
                  ? 'Rename (sheet)'
                  : 'Duplicate (sheet)';

              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Tidy Up',
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpSetup),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        label: renameLabel,
                        onPressed: _previewItem == null || _previewItem!.type == FileItemType.folder
                            ? null
                            : () => _openRenameSheet(_previewItem!),
                      ),
                    ),
                    if (_operationMode == RenameOperationMode.duplicate &&
                        _currentSource == FileSource.phone &&
                        _phoneCurrentPath != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.secondary(
                          label: 'Replace Originals In Folder',
                          onPressed: _replaceCurrentFolderOriginals,
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Tidy Up',
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpSetup),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton.primary(
                          label: renameLabel,
                          onPressed: _previewItem == null || _previewItem!.type == FileItemType.folder
                              ? null
                              : () => _openRenameSheet(_previewItem!),
                        ),
                      ),
                    ],
                  ),
                  if (_operationMode == RenameOperationMode.duplicate &&
                      _currentSource == FileSource.phone &&
                      _phoneCurrentPath != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Replace Originals In Folder',
                        onPressed: _replaceCurrentFolderOriginals,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const minLeftWidth = 300.0;
        const minRightWidth = 360.0;
        const dividerWidth = 1.0;
        const totalMinWidth = minLeftWidth + dividerWidth + minRightWidth;

        if (constraints.maxWidth < totalMinWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalMinWidth,
              height: constraints.maxHeight,
              child: Row(
                children: [
                  SizedBox(width: minLeftWidth, child: leftPanel),
                  const VerticalDivider(width: dividerWidth),
                  SizedBox(width: minRightWidth, child: rightPanel),
                ],
              ),
            ),
          );
        }

        return Row(
          children: [
            Expanded(flex: 4, child: leftPanel),
            const VerticalDivider(width: dividerWidth),
            Expanded(flex: 6, child: rightPanel),
          ],
        );
      },
    );
  }

  Widget _iconFor(FileItemType type) {
    switch (type) {
      case FileItemType.folder:
        return const Icon(Icons.folder_outlined);
      case FileItemType.pdf:
        return const Icon(Icons.picture_as_pdf_outlined);
      case FileItemType.image:
        return const Icon(Icons.image_outlined);
      case FileItemType.text:
        return const Icon(Icons.text_snippet_outlined);
      case FileItemType.document:
        return const Icon(Icons.description_outlined);
    }
  }
}
