import 'package:file_picker/file_picker.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/use_cases/export_phone_files_to_usb_use_case.dart';
import 'package:file_tidy_app/core/use_cases/import_local_folder_use_case.dart';
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

  late final ExportPhoneFilesToUsbUseCase _exportPhoneFilesToUsbUseCase;
  late final ImportLocalFolderUseCase _importLocalFolderUseCase;

  bool _busy = false;
  int _lastCopiedCount = 0;

  @override
  void initState() {
    super.initState();
    _exportPhoneFilesToUsbUseCase = ExportPhoneFilesToUsbUseCase(
      _dependencies.fileRepository,
      _dependencies.usbExportService,
    );
    _importLocalFolderUseCase = ImportLocalFolderUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
    );
  }

  Future<void> _archiveToUsb() async {
    final destinationPath = await FilePicker.platform.getDirectoryPath();
    if (destinationPath == null) {
      return;
    }

    setState(() => _busy = true);
    final copied = await _exportPhoneFilesToUsbUseCase(
      destinationFolderPath: destinationPath,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      _lastCopiedCount = copied;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $copied file(s) to selected folder.')),
    );
  }

  Future<void> _restoreFromUsb() async {
    setState(() => _busy = true);
    final result = await _importLocalFolderUseCase();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    final copied = result?.files.length ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported $copied file(s) from selected folder.')),
    );
  }

  void _verifyCopiedFiles() {
    final message = _lastCopiedCount == 0
        ? 'No recent archive result yet. Run Archive selected files first.'
        : 'Last archive copied $_lastCopiedCount file(s).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Archive')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text('Use USB-C storage for archive/restore without cloud upload.'),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: _busy ? 'Working...' : 'Archive imported phone files',
            onPressed: _busy ? null : _archiveToUsb,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(
            label: _busy ? 'Working...' : 'Restore from selected folder',
            onPressed: _busy ? null : _restoreFromUsb,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.primary(
            label: 'Verify copied files',
            onPressed: _verifyCopiedFiles,
          ),
        ],
      ),
    );
  }
}
