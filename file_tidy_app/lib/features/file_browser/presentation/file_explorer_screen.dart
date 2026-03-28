import 'dart:io';

import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/get_ai_rename_suggestions_use_case.dart';
import 'package:file_tidy_app/core/use_cases/import_local_folder_use_case.dart';
import 'package:file_tidy_app/core/use_cases/import_local_files_use_case.dart';
import 'package:file_tidy_app/core/use_cases/rename_file_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/components/app_text_input.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:file_tidy_app/features/preview/presentation/file_preview_screen.dart';
import 'package:file_tidy_app/features/preview/presentation/preview_pane.dart';
import 'package:file_tidy_app/features/rename_manual/presentation/rename_sheet.dart';
import 'package:flutter/material.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  final _dependencies = DependencyContainer.instance;

  late final RenameFileUseCase _renameFileUseCase;
  late final GetAiRenameSuggestionsUseCase _getAiRenameSuggestionsUseCase;
  late final ImportLocalFilesUseCase _importLocalFilesUseCase;
  late final ImportLocalFolderUseCase _importLocalFolderUseCase;
  late final TextEditingController _renameController;

  FileSource _currentSource = FileSource.phone;
  FileItem? _focusedItem;
  FileItem? _previewItem;
  bool _loading = false;
  List<FileItem> _items = [];

  String? _phoneRootPath;
  String? _phoneCurrentPath;

  bool get _isPhoneEmptyState =>
      _currentSource == FileSource.phone && _items.isEmpty;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController();
    _renameFileUseCase = RenameFileUseCase(_dependencies.fileRepository);
    _getAiRenameSuggestionsUseCase = GetAiRenameSuggestionsUseCase(
      _dependencies.aiRenameService,
    );
    _importLocalFilesUseCase = ImportLocalFilesUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
    );
    _importLocalFolderUseCase = ImportLocalFolderUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
    );
    _loadItems();
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
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
        _syncPhoneNavigation(values);
      } else {
        _focusedItem = values.where((item) => item.type != FileItemType.folder).firstOrNull;
        _previewItem = _focusedItem;
      }
      _renameController.text = _focusedItem?.name ?? '';
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
    if (visible.isNotEmpty) {
      _focusedItem ??= visible.first;
      if (_previewItem == null || _previewItem!.type == FileItemType.folder) {
        _previewItem = visible.firstWhere(
          (item) => item.type != FileItemType.folder,
          orElse: () => visible.first,
        );
      }
    }
  }

  Future<void> _importLocalFiles() async {
    if (_currentSource != FileSource.phone) {
      return;
    }
    final files = await _importLocalFilesUseCase();
    if (!mounted) {
      return;
    }
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files imported.')),
      );
      return;
    }
    _phoneRootPath ??= _deriveCommonRootPath(files);
    _phoneCurrentPath ??= _phoneRootPath;
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${files.length} file(s).')),
    );
  }

  Future<void> _importLocalFolder() async {
    if (_currentSource != FileSource.phone) {
      return;
    }
    final result = await _importLocalFolderUseCase();
    if (!mounted) {
      return;
    }
    if (result == null || result.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No folder files imported.')),
      );
      return;
    }
    _phoneRootPath = result.rootPath;
    _phoneCurrentPath = result.rootPath;
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${result.files.length} file(s) from folder.')),
    );
  }

  Future<void> _openRenameSheet(FileItem item) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RenameSheet(
        currentName: item.name,
        suggestionsLoader: () => _getAiRenameSuggestionsUseCase(
          currentName: item.name,
          context: item.type.name,
        ),
      ),
    );
    if (value == null || value.isEmpty || value == item.name) {
      return;
    }

    await _renameFileUseCase(fileId: item.id, newName: value);
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Renamed to "$value"')),
    );
  }

  Future<void> _renameInstantlyFromLeft() async {
    final item = _focusedItem;
    if (item == null || item.type == FileItemType.folder) {
      return;
    }
    final value = _renameController.text.trim();
    if (value.isEmpty || value == item.name) {
      return;
    }
    await _renameFileUseCase(fileId: item.id, newName: value);
    await _loadItems();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Renamed to "$value"')),
    );
  }

  Future<void> _openPreviewPortrait(FileItem item) async {
    if (item.type == FileItemType.folder) {
      _navigateIntoFolder(item.path ?? '');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FilePreviewScreen(
          item: item,
          onRenamePressed: () async {
            Navigator.of(context).pop();
            await _openRenameSheet(item);
          },
          onTidyUpPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpSetup),
        ),
      ),
    );
    await _loadItems();
  }

  void _navigateIntoFolder(String folderPath) {
    if (_currentSource != FileSource.phone) {
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
      _renameController.text = _focusedItem?.name ?? '';
    });
  }

  void _goUpOneFolder() {
    if (_currentSource != FileSource.phone ||
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
      _renameController.text = _focusedItem?.name ?? '';
    });
  }

  void _focusItem(FileItem item) {
    setState(() {
      _focusedItem = item;
      _renameController.text = item.name;
    });
  }

  void _openItemInLandscape(FileItem item) {
    if (_currentSource == FileSource.phone && item.type == FileItemType.folder) {
      _navigateIntoFolder(item.path ?? _phoneCurrentPath ?? '');
      return;
    }
    setState(() {
      _previewItem = item;
      _focusedItem = item;
      _renameController.text = item.name;
    });
  }

  List<FileItem> _visiblePhoneEntries() {
    final current = _phoneCurrentPath;
    if (current == null) {
      return [];
    }

    final separator = Platform.pathSeparator;
    final normalizedCurrent = current.endsWith(separator) ? current : '$current$separator';
    final folderPaths = <String>{};
    final files = <FileItem>[];

    for (final item in _items) {
      if (item.path == null) {
        continue;
      }
      final path = item.path!;
      if (!path.startsWith(normalizedCurrent) && item.parentPath != current) {
        continue;
      }

      if (item.parentPath == current) {
        files.add(item);
        continue;
      }

      final remainder = path.substring(normalizedCurrent.length);
      if (!remainder.contains(separator)) {
        files.add(item.copyWith(name: remainder));
        continue;
      }
      final firstSegment = remainder.split(separator).first;
      folderPaths.add('$current$separator$firstSegment');
    }

    final folderItems = folderPaths
        .map(
          (folder) => FileItem(
            id: 'folder_$folder',
            name: folder.split(separator).last,
            type: FileItemType.folder,
            source: FileSource.phone,
            path: folder,
            parentPath: current,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [...folderItems, ...files];
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          if (_currentSource == FileSource.phone)
            IconButton(
              icon: const Icon(Icons.file_open_outlined),
              tooltip: 'Import file(s)',
              onPressed: _importLocalFiles,
            ),
          if (_currentSource == FileSource.phone)
            IconButton(
              icon: const Icon(Icons.drive_folder_upload_outlined),
              tooltip: 'Import folder',
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
                  if (value != FileSource.phone) {
                    _phoneCurrentPath = null;
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
          : _isPhoneEmptyState
              ? _buildPhoneEmptyState()
              : isLandscape
                  ? _buildLandscape()
                  : _buildPortrait(),
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

  Widget _buildPortrait() {
    final entries = _currentSource == FileSource.phone ? _visiblePhoneEntries() : _items;
    return Column(
      children: [
        if (_currentSource == FileSource.phone && _phoneCurrentPath != null)
          ListTile(
            leading: const Icon(Icons.folder_open_outlined),
            title: Text(_phoneCurrentPath!),
            subtitle: Text(_phoneRootPath == _phoneCurrentPath ? 'Root folder' : 'Subfolder'),
            trailing: _phoneRootPath == _phoneCurrentPath
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _goUpOneFolder,
                  ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final item = entries[index];
              return ListTile(
                leading: _iconFor(item.type),
                title: Text(item.name),
                subtitle: Text(item.type == FileItemType.folder ? item.type.name : item.parentPath),
                trailing: item.type == FileItemType.folder
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.drive_file_rename_outline),
                        onPressed: () => _openRenameSheet(item),
                      ),
                onTap: () {
                  if (item.type == FileItemType.folder) {
                    _navigateIntoFolder(item.path ?? '');
                    return;
                  }
                  _openPreviewPortrait(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.file_open_outlined, size: 42),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No phone folder loaded yet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Choose a folder from your phone to start browsing.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: 'Open phone folder',
                onPressed: _importLocalFolder,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: 'Or import file(s)',
                onPressed: _importLocalFiles,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscape() {
    final entries = _currentSource == FileSource.phone ? _visiblePhoneEntries() : _items;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              if (_currentSource == FileSource.phone && _phoneCurrentPath != null)
                ListTile(
                  leading: const Icon(Icons.folder_open_outlined),
                  title: Text(_phoneCurrentPath!),
                  trailing: _phoneRootPath == _phoneCurrentPath
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: _goUpOneFolder,
                        ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final item = entries[index];
                    final selected = _focusedItem?.id == item.id;
                    return InkWell(
                      onTap: () => _focusItem(item),
                      onDoubleTap: () => _openItemInLandscape(item),
                      child: ListTile(
                        selected: selected,
                        leading: _iconFor(item.type),
                        title: Text(item.name),
                        subtitle: Text(item.type == FileItemType.folder ? item.type.name : item.parentPath),
                      ),
                    );
                  },
                ),
              ),
              if (_focusedItem != null && _focusedItem!.type != FileItemType.folder)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      AppTextInput(
                        controller: _renameController,
                        label: 'Rename selected file',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.primary(
                          label: 'Rename',
                          onPressed: _renameInstantlyFromLeft,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                child: PreviewPane(item: _previewItem),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                              label: 'Tidy Up',
                              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.tidyUpSetup),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton.primary(
                              label: 'Rename (sheet)',
                              onPressed: _previewItem == null || _previewItem!.type == FileItemType.folder
                                  ? null
                                  : () => _openRenameSheet(_previewItem!),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
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
                            label: 'Rename (sheet)',
                            onPressed: _previewItem == null || _previewItem!.type == FileItemType.folder
                                ? null
                                : () => _openRenameSheet(_previewItem!),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
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
