import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict_resolution.dart';
import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';
import 'package:file_tidy_app/core/models/usb_archive_retention_mode.dart';
import 'package:file_tidy_app/core/use_cases/execute_usb_archive_use_case.dart';
import 'package:file_tidy_app/core/use_cases/prepare_usb_archive_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class UsbArchiveScreen extends StatefulWidget {
  const UsbArchiveScreen({super.key});

  @override
  State<UsbArchiveScreen> createState() => _UsbArchiveScreenState();
}

class _UsbArchiveScreenState extends State<UsbArchiveScreen> {
  final _dependencies = DependencyContainer.instance;

  late final PrepareUsbArchiveUseCase _prepareUsbArchiveUseCase;
  late final ExecuteUsbArchiveUseCase _executeUsbArchiveUseCase;

  bool _busy = false;
  LocalFolderImportResult? _selectedFolder;
  List<FileItem> _selectedFiles = const [];
  String? _destinationFolderPath;
  List<UsbArchiveConflict> _conflicts = const [];
  UsbArchiveConflictResolution _conflictResolution = UsbArchiveConflictResolution.keepBoth;
  UsbArchiveRetentionMode _retentionMode = UsbArchiveRetentionMode.keepOnPhone;
  UsbArchiveExecutionResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _prepareUsbArchiveUseCase = PrepareUsbArchiveUseCase(
      _dependencies.usbExportService,
    );
    _executeUsbArchiveUseCase = ExecuteUsbArchiveUseCase(
      _dependencies.usbExportService,
      _dependencies.localFileMutationService,
    );
  }

  Future<void> _chooseFolderToArchive() async {
    final result = await _dependencies.localFilePickerService.pickFolderItems();
    if (!mounted || result == null) {
      return;
    }
    final files = result.files.where((item) => item.type != FileItemType.folder).toList();
    setState(() {
      _selectedFolder = result;
      _selectedFiles = files;
      _destinationFolderPath = null;
      _conflicts = const [];
      _lastResult = null;
    });
  }

  Future<void> _prepareArchive() async {
    if (_selectedFiles.isEmpty || _selectedFolder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a folder to archive first.')),
      );
      return;
    }

    final destinationPath = await _dependencies.localFilePickerService.pickDirectoryPath();
    if (!mounted || destinationPath == null) {
      return;
    }

    final confirmed = await _showArchiveConfirmation(
      folderPath: _selectedFolder!.rootPath,
      fileCount: _selectedFiles.length,
      destinationFolderPath: destinationPath,
    );
    if (!mounted || confirmed != true) {
      return;
    }

    setState(() => _busy = true);
    final conflicts = await _prepareUsbArchiveUseCase(
      files: _selectedFiles,
      destinationFolderPath: destinationPath,
    );
    setState(() {
      _busy = false;
      _destinationFolderPath = destinationPath;
      _conflicts = conflicts;
      _lastResult = null;
    });
  }

  Future<void> _runArchive() async {
    if (_selectedFiles.isEmpty || _destinationFolderPath == null) {
      return;
    }

    setState(() => _busy = true);
    final result = await _executeUsbArchiveUseCase(
      files: _selectedFiles,
      destinationFolderPath: _destinationFolderPath!,
      conflictResolution: _conflictResolution,
      retentionMode: _retentionMode,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _lastResult = result;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Archived ${result.copiedCount} file(s). Verified ${result.verifiedCount}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archive Your Memories')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Copy a folder from your phone to a USB drive with a simple, safe flow.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _ArchiveStepCard(
            title: '1. Choose folder to archive',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFolder?.rootPath ?? 'No folder chosen yet.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Files ready: ${_selectedFiles.length}'),
                const SizedBox(height: AppSpacing.sm),
                AppButton.secondary(
                  label: 'Choose folder',
                  onPressed: _busy ? null : _chooseFolderToArchive,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ArchiveStepCard(
            title: '2. Choose what happens after archive',
            child: Column(
              children: UsbArchiveRetentionMode.values
                  .map(
                    (mode) => _SelectionTile(
                      title: mode.label,
                      subtitle: mode.helperText,
                      selected: _retentionMode == mode,
                      onTap: _busy ? null : () => setState(() => _retentionMode = mode),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.primary(
            label: _busy ? 'Working...' : 'Archive now',
            onPressed: _busy ? null : _prepareArchive,
          ),
          if (_destinationFolderPath != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ArchiveStepCard(
              title: '3. USB destination',
              child: Text(
                _destinationFolderPath!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_destinationFolderPath != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ArchiveStepCard(
              title: '4. Matching names found on USB',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conflicts.isEmpty
                        ? 'No matching file names were found.'
                        : 'Choose how to handle ${_conflicts.length} matching file name(s).',
                  ),
                  if (_conflicts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ...UsbArchiveConflictResolution.values.map(
                      (resolution) => _SelectionTile(
                        title: resolution.label,
                        subtitle: resolution.helperText,
                        selected: _conflictResolution == resolution,
                        onTap: _busy
                            ? null
                            : () => setState(() => _conflictResolution = resolution),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _conflicts.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conflict = _conflicts[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                conflict.sourceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Keep both: ${conflict.suggestedName}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.primary(
                    label: _busy ? 'Working...' : 'Start archive',
                    onPressed: _busy ? null : _runArchive,
                  ),
                ],
              ),
            ),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ArchiveStepCard(
              title: 'Archive result',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Copied: ${_lastResult!.copiedCount}'),
                  Text('Verified: ${_lastResult!.verifiedCount}'),
                  Text('Renamed copies: ${_lastResult!.renamedCopyCount}'),
                  Text('Replaced old files: ${_lastResult!.replacedCount}'),
                  Text('Failed: ${_lastResult!.failedCount}'),
                  if (_retentionMode == UsbArchiveRetentionMode.removeFromPhone)
                    Text('Removed from phone: ${_lastResult!.removedOriginalCount}'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showArchiveConfirmation({
    required String folderPath,
    required int fileCount,
    required String destinationFolderPath,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm archive'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Folder: $folderPath'),
              const SizedBox(height: AppSpacing.xs),
              Text('Files: $fileCount'),
              const SizedBox(height: AppSpacing.xs),
              Text('USB folder: $destinationFolderPath'),
              const SizedBox(height: AppSpacing.sm),
              Text(_retentionMode.helperText),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _ArchiveStepCard extends StatelessWidget {
  const _ArchiveStepCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            color: selected ? colorScheme.primary.withValues(alpha: 0.08) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? colorScheme.primary : colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
