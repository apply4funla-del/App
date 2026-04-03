import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict.dart';
import 'package:file_tidy_app/core/models/usb_archive_conflict_resolution.dart';
import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';
import 'package:file_tidy_app/core/models/usb_archive_plan.dart';
import 'package:file_tidy_app/core/models/usb_archive_retention_mode.dart';
import 'package:file_tidy_app/core/use_cases/execute_usb_archive_use_case.dart';
import 'package:file_tidy_app/core/use_cases/prepare_photo_archive_use_case.dart';
import 'package:file_tidy_app/core/use_cases/prepare_usb_archive_use_case.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:file_tidy_app/features/usb_archive/presentation/widgets/archive_flow_widgets.dart';
import 'package:flutter/material.dart';

class UsbArchivePhotosScreen extends StatefulWidget {
  const UsbArchivePhotosScreen({super.key});

  @override
  State<UsbArchivePhotosScreen> createState() => _UsbArchivePhotosScreenState();
}

class _UsbArchivePhotosScreenState extends State<UsbArchivePhotosScreen> {
  final _dependencies = DependencyContainer.instance;

  late final PreparePhotoArchiveUseCase _preparePhotoArchiveUseCase;
  late final PrepareUsbArchiveUseCase _prepareUsbArchiveUseCase;
  late final ExecuteUsbArchiveUseCase _executeUsbArchiveUseCase;

  UsbArchivePlan? _plan;
  List<UsbArchiveConflict> _conflicts = const [];
  UsbArchiveConflictResolution _conflictResolution = UsbArchiveConflictResolution.keepBoth;
  UsbArchiveRetentionMode _retentionMode = UsbArchiveRetentionMode.keepOnPhone;
  UsbArchiveExecutionResult? _result;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _preparePhotoArchiveUseCase = PreparePhotoArchiveUseCase(
      _dependencies.mediaSourceService,
      _dependencies.usbStorageService,
    );
    _prepareUsbArchiveUseCase = PrepareUsbArchiveUseCase(_dependencies.usbExportService);
    _executeUsbArchiveUseCase = ExecuteUsbArchiveUseCase(
      _dependencies.usbExportService,
      _dependencies.localFileMutationService,
    );
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    final plan = await _preparePhotoArchiveUseCase();
    if (!mounted) {
      return;
    }
    if (plan == null) {
      setState(() => _loading = false);
      Navigator.of(context).pushReplacementNamed(AppRoutes.usbArchiveMissing);
      return;
    }
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  Future<void> _prepareArchive() async {
    final plan = _plan;
    if (plan == null) {
      return;
    }
    final confirmed = await _showConfirmation(plan);
    if (!mounted || confirmed != true) {
      return;
    }
    setState(() => _busy = true);
    final conflicts = await _prepareUsbArchiveUseCase(
      files: plan.files,
      destinationFolderPath: plan.destinationFolderPath,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _conflicts = conflicts;
      _result = null;
    });
  }

  Future<void> _runArchive() async {
    final plan = _plan;
    if (plan == null) {
      return;
    }

    setState(() => _busy = true);
    final result = await _executeUsbArchiveUseCase(
      files: plan.files,
      destinationFolderPath: plan.destinationFolderPath,
      conflictResolution: _conflictResolution,
      retentionMode: _retentionMode,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archive Photos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plan == null
              ? const SizedBox.shrink()
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ArchiveStepCard(
                              title: 'Photo archive ready',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Source: ${_plan!.sourceRootPath}', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('USB folder: ${_plan!.destinationLabel}'),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('Files found: ${_plan!.files.length}'),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ArchiveStepCard(
                              title: 'After archive',
                              child: Column(
                                children: UsbArchiveRetentionMode.values
                                    .map(
                                      (mode) => ArchiveSelectionTile(
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
                            ArchivePrimaryAction(
                              label: _busy ? 'Working...' : 'Archive now',
                              onPressed: _busy ? null : _prepareArchive,
                            ),
                            if (_conflicts.isNotEmpty || _result != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ArchiveStepCard(
                                        title: 'Matching names on USB',
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _conflicts.isEmpty
                                                  ? 'No matching names found.'
                                                  : 'Choose how to handle ${_conflicts.length} matching name(s).',
                                            ),
                                            if (_conflicts.isNotEmpty) ...[
                                              const SizedBox(height: AppSpacing.sm),
                                              ...UsbArchiveConflictResolution.values.map(
                                                (resolution) => ArchiveSelectionTile(
                                                  title: resolution.label,
                                                  subtitle: resolution.helperText,
                                                  selected: _conflictResolution == resolution,
                                                  onTap: _busy
                                                      ? null
                                                      : () => setState(() => _conflictResolution = resolution),
                                                ),
                                              ),
                                              _ConflictList(conflicts: _conflicts),
                                              const SizedBox(height: AppSpacing.sm),
                                              ArchivePrimaryAction(
                                                label: _busy ? 'Working...' : 'Start archive',
                                                onPressed: _busy ? null : _runArchive,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (_result != null) ...[
                                        const SizedBox(height: AppSpacing.md),
                                        ArchiveResultCard(
                                          result: _result!,
                                          removedFromPhoneMode:
                                              _retentionMode == UsbArchiveRetentionMode.removeFromPhone,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<bool?> _showConfirmation(UsbArchivePlan plan) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm photo archive'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Source: ${plan.sourceRootPath}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Destination: ${plan.destinationLabel}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Files: ${plan.files.length}'),
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

class _ConflictList extends StatelessWidget {
  const _ConflictList({
    required this.conflicts,
  });

  final List<UsbArchiveConflict> conflicts;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: conflicts.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final conflict = conflicts[index];
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
    );
  }
}
