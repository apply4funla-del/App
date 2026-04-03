import 'dart:io';

import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/config/feature_flags.dart';
import 'package:file_tidy_app/core/models/explorer_launch_config.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';
import 'package:file_tidy_app/core/models/rename_operation_mode.dart';
import 'package:file_tidy_app/core/use_cases/duplicate_file_use_case.dart';
import 'package:file_tidy_app/core/use_cases/import_local_folder_use_case.dart';
import 'package:file_tidy_app/core/use_cases/rename_file_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:file_tidy_app/features/preview/presentation/preview_pane.dart';
import 'package:flutter/material.dart';

enum _ExplorerSortType { name, modifiedDate, fileSize }

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
  late final ImportLocalFolderUseCase _importLocalFolderUseCase;

  final TextEditingController _renameBaseController = TextEditingController();
  final FocusNode _renameBaseFocusNode = FocusNode();

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
  String? _renameTargetFileId;
  String _renameLockedExtension = '';
  bool _renameApplying = false;
  bool _explorerToolbarVisible = false;
  _ExplorerSortType _sortType = _ExplorerSortType.name;

  List<FileItem> get _currentPhoneEntries {
    if (!_phoneFolderBrowsingEnabled || _phoneCurrentPath == null) {
      return _sortEntries(_items);
    }
    return _visiblePhoneEntries();
  }

  @override
  void initState() {
    super.initState();
    _renameFileUseCase = RenameFileUseCase(_dependencies.fileRepository);
    _duplicateFileUseCase = DuplicateFileUseCase(_dependencies.fileRepository);
    _importLocalFolderUseCase = ImportLocalFolderUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
      _dependencies.storagePermissionService,
    );
    _renameBaseFocusNode.addListener(() {
      if (!_renameBaseFocusNode.hasFocus) {
        _commitInlineRename();
      }
    });

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

  @override
  void dispose() {
    _renameBaseFocusNode.dispose();
    _renameBaseController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final values = await _dependencies.fileRepository.listItems(_currentSource);
    if (!mounted) {
      return;
    }
    final previousFocusedId = _focusedItem?.id;
    final previousPreviewId = _previewItem?.id;

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
      if (previousFocusedId != null) {
        final candidates = _currentSource == FileSource.phone ? _currentPhoneEntries : values;
        _focusedItem = candidates.where((item) => item.id == previousFocusedId).firstOrNull ?? _focusedItem;
      }
      if (previousPreviewId != null) {
        final matchedPreview = values.where((item) => item.id == previousPreviewId).firstOrNull;
        if (matchedPreview != null && matchedPreview.type != FileItemType.folder) {
          _previewItem = matchedPreview;
        }
      }
      _loading = false;
    });
    _syncInlineRenameDraft();
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

  void _syncInlineRenameDraft() {
    final item = _previewItem;
    if (item == null || item.type == FileItemType.folder) {
      _renameTargetFileId = null;
      _renameLockedExtension = '';
      if (_renameBaseController.text.isNotEmpty) {
        _renameBaseController.clear();
      }
      return;
    }
    if (_renameTargetFileId == item.id) {
      return;
    }
    final (base, extension) = _splitName(item.name);
    _renameTargetFileId = item.id;
    _renameLockedExtension = extension;
    _renameBaseController.value = TextEditingValue(
      text: base,
      selection: TextSelection.collapsed(offset: base.length),
    );
  }

  Future<void> _commitInlineRename() async {
    if (_renameApplying) {
      return;
    }
    final item = _previewItem;
    if (item == null || item.type == FileItemType.folder) {
      return;
    }
    final base = _renameBaseController.text.trim();
    if (base.isEmpty) {
      _syncInlineRenameDraft();
      return;
    }
    final nextName =
        _renameLockedExtension.isEmpty ? base : '$base.$_renameLockedExtension';
    if (nextName == item.name) {
      return;
    }

    _renameApplying = true;
    try {
      await _applyRenameChange(item: item, newName: nextName);
      if (!mounted) {
        return;
      }
      _syncInlineRenameDraft();
    } finally {
      _renameApplying = false;
    }
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
    _syncInlineRenameDraft();
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
    _syncInlineRenameDraft();
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
    _syncInlineRenameDraft();
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
    _syncInlineRenameDraft();
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

    return _sortEntries([...folderMap.values, ...files]);
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
      final stream = directory.list(followLinks: false).handleError((_) {});
      await for (final entity in stream) {
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

  List<FileItem> _sortEntries(List<FileItem> items) {
    final folders = items.where((item) => item.type == FileItemType.folder).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final files = items.where((item) => item.type != FileItemType.folder).toList();

    switch (_sortType) {
      case _ExplorerSortType.name:
        files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _ExplorerSortType.modifiedDate:
        files.sort((a, b) {
          final aTs = a.modifiedAt?.millisecondsSinceEpoch ?? 0;
          final bTs = b.modifiedAt?.millisecondsSinceEpoch ?? 0;
          final byDate = bTs.compareTo(aTs);
          if (byDate != 0) {
            return byDate;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case _ExplorerSortType.fileSize:
        files.sort((a, b) {
          final aSize = a.sizeBytes ?? 0;
          final bSize = b.sizeBytes ?? 0;
          final bySize = bSize.compareTo(aSize);
          if (bySize != 0) {
            return bySize;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return [...folders, ...files];
  }

  String _sortTypeLabel(_ExplorerSortType type) {
    switch (type) {
      case _ExplorerSortType.name:
        return 'Name';
      case _ExplorerSortType.modifiedDate:
        return 'Date';
      case _ExplorerSortType.fileSize:
        return 'Size';
    }
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
        toolbarHeight: _explorerToolbarVisible ? kToolbarHeight : 0,
        title: const Text('Explorer'),
        bottom: _buildRenameAppBarBottom(),
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
          PopupMenuButton<_ExplorerSortType>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (_sortType == value) {
                return;
              }
              setState(() => _sortType = value);
            },
            itemBuilder: (context) {
              return _ExplorerSortType.values
                  .map(
                    (type) => PopupMenuItem<_ExplorerSortType>(
                      value: type,
                      child: Text(
                        _sortType == type
                            ? 'Sort: ${_sortTypeLabel(type)} (Current)'
                            : 'Sort: ${_sortTypeLabel(type)}',
                      ),
                    ),
                  )
                  .toList();
            },
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
      bottomNavigationBar: _buildExplorerBottomBar(),
    );
  }

  Widget _buildSplitExplorer() {
    final entries = _currentSource == FileSource.phone ? _currentPhoneEntries : _sortEntries(_items);

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

  PreferredSizeWidget? _buildRenameAppBarBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _explorerToolbarVisible
                    ? Icons.visibility_off_outlined
                    : Icons.tune_outlined,
              ),
              tooltip: _explorerToolbarVisible
                  ? 'Hide explorer controls'
                  : 'Show explorer controls',
              onPressed: () {
                setState(() {
                  _explorerToolbarVisible = !_explorerToolbarVisible;
                });
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _buildInlineRenameEditor(compact: true),
            ),
          ],
        ),
      ),
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

  Widget _buildInlineRenameEditor({bool compact = false}) {
    final item = _previewItem;
    final canRename = item != null && item.type != FileItemType.folder;
    final label = _operationMode == RenameOperationMode.workInPlace ? 'Rename' : 'Duplicate As';
    final extensionLabel =
        canRename && _renameLockedExtension.isNotEmpty ? '.$_renameLockedExtension' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _renameBaseController,
                focusNode: _renameBaseFocusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _commitInlineRename(),
                enabled: canRename && !_renameApplying,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: canRename ? 'Enter file name' : 'Select a file to rename',
                  isDense: compact,
                  contentPadding: compact
                      ? const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        )
                      : null,
                ),
              ),
            ),
            if (extensionLabel.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                extensionLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExplorerBottomBar() {
    final actions = _bottomBarActions();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 640) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildBottomNavButton(actions[0])),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildBottomNavButton(actions[1])),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildBottomNavButton(actions[2])),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _buildBottomNavButton(actions[3])),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildBottomNavButton(actions[4])),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  Expanded(child: _buildBottomNavButton(actions[index])),
                  if (index < actions.length - 1) const SizedBox(width: AppSpacing.xs),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavButton(
    ({String label, VoidCallback onPressed, bool primary}) action,
  ) {
    if (action.primary) {
      return AppButton.primary(label: action.label, onPressed: action.onPressed);
    }
    return AppButton.secondary(label: action.label, onPressed: action.onPressed);
  }

  List<({String label, VoidCallback onPressed, bool primary})> _bottomBarActions() {
    return [
      (
        label: 'History',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.history),
        primary: false,
      ),
      (
        label: 'Settings',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.privacy),
        primary: true,
      ),
      (
        label: 'Privacy',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
        primary: false,
      ),
      (
        label: 'USB Archive',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.usbArchive),
        primary: false,
      ),
      (
        label: 'AI Assist',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpSetup),
        primary: false,
      ),
    ];
  }

  (String, String) _splitName(String fullName) {
    final dotIndex = fullName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fullName.length - 1) {
      return (fullName, '');
    }
    final base = fullName.substring(0, dotIndex);
    final extension = fullName.substring(dotIndex + 1);
    return (base, extension);
  }
}
