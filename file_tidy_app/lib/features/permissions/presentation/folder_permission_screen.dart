import 'dart:io';

import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/explorer_launch_config.dart';
import 'package:file_tidy_app/core/models/local_folder_import_result.dart';
import 'package:file_tidy_app/core/use_cases/import_local_folder_use_case.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class FolderPermissionScreen extends StatefulWidget {
  const FolderPermissionScreen({
    super.key,
    required this.config,
  });

  final ExplorerLaunchConfig config;

  @override
  State<FolderPermissionScreen> createState() => _FolderPermissionScreenState();
}

class _FolderPermissionScreenState extends State<FolderPermissionScreen> {
  final _dependencies = DependencyContainer.instance;
  late final ImportLocalFolderUseCase _importLocalFolderUseCase;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _importLocalFolderUseCase = ImportLocalFolderUseCase(
      _dependencies.localFilePickerService,
      _dependencies.fileRepository,
    );
  }

  Future<void> _grantAndContinue() async {
    setState(() => _loading = true);
    final result = await _importLocalFolderUseCase();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (result == null || !_hasBrowsableEntries(result)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a folder to amend the content.'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.explorer,
      (route) => false,
      arguments: ExplorerLaunchConfig(
        source: widget.config.source,
        operationMode: widget.config.operationMode,
        requestFolderOnStart: false,
        initialPhoneRootPath: result.rootPath,
      ),
    );
  }

  bool _hasBrowsableEntries(LocalFolderImportResult result) {
    final separator = Platform.pathSeparator;
    final normalizedRoot = result.rootPath.endsWith(separator)
        ? result.rootPath
        : '${result.rootPath}$separator';

    for (final item in result.files) {
      final path = item.path;
      if (path == null || path == result.rootPath) {
        continue;
      }
      if (item.parentPath == result.rootPath || path.startsWith(normalizedRoot)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'To amend files in root folder, you must grant folder permission now.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'You will choose the folder in the system picker. Then we open Explorer directly.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: _loading ? 'Loading...' : 'Grant Folder Permission',
            onPressed: _loading ? null : _grantAndContinue,
          ),
        ],
      ),
    );
  }
}
