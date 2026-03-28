import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/get_ai_rename_suggestions_use_case.dart';
import 'package:file_tidy_app/core/use_cases/rename_file_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
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

  FileSource _currentSource = FileSource.phone;
  FileItem? _selectedItem;
  bool _loading = false;
  List<FileItem> _items = [];

  @override
  void initState() {
    super.initState();
    _renameFileUseCase = RenameFileUseCase(_dependencies.fileRepository);
    _getAiRenameSuggestionsUseCase = GetAiRenameSuggestionsUseCase(
      _dependencies.aiRenameService,
    );
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    final values = await _dependencies.fileRepository.listItems(_currentSource);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = values;
      _selectedItem = values.where((item) => item.type != FileItemType.folder).firstOrNull;
      _loading = false;
    });
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

  Future<void> _openPreviewPortrait(FileItem item) async {
    if (item.type == FileItemType.folder) {
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

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: DropdownButton<FileSource>(
              value: _currentSource,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                setState(() => _currentSource = value);
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
          : isLandscape
              ? _buildLandscape()
              : _buildPortrait(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
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
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait() {
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return ListTile(
          leading: _iconFor(item.type),
          title: Text(item.name),
          subtitle: Text(item.type.name),
          trailing: item.type == FileItemType.folder
              ? null
              : IconButton(
                  icon: const Icon(Icons.drive_file_rename_outline),
                  onPressed: () => _openRenameSheet(item),
                ),
          onTap: () => _openPreviewPortrait(item),
        );
      },
    );
  }

  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return ListTile(
                selected: _selectedItem?.id == item.id,
                leading: _iconFor(item.type),
                title: Text(item.name),
                subtitle: Text(item.type.name),
                onTap: () => setState(() => _selectedItem = item),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(child: PreviewPane(item: _selectedItem)),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
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
                        label: 'Rename',
                        onPressed: _selectedItem == null || _selectedItem!.type == FileItemType.folder
                            ? null
                            : () => _openRenameSheet(_selectedItem!),
                      ),
                    ),
                  ],
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
