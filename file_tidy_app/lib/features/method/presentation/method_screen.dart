import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/core/models/explorer_launch_config.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/models/rename_operation_mode.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class MethodScreen extends StatefulWidget {
  const MethodScreen({
    super.key,
    required this.source,
  });

  final FileSource source;

  @override
  State<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends State<MethodScreen> {
  RenameOperationMode _mode = RenameOperationMode.workInPlace;

  void _continue() {
    final config = ExplorerLaunchConfig(
      source: widget.source,
      operationMode: _mode,
      requestFolderOnStart: widget.source == FileSource.phone,
    );

    if (widget.source == FileSource.phone && _mode == RenameOperationMode.workInPlace) {
      Navigator.of(context).pushNamed(
        AppRoutes.folderPermission,
        arguments: config,
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.explorer,
      (route) => false,
      arguments: config,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Method')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Source: ${widget.source.label}'),
          const SizedBox(height: AppSpacing.sm),
          const Text('Choose how you want to work with files:'),
          const SizedBox(height: AppSpacing.md),
          _methodTile(
            mode: RenameOperationMode.workInPlace,
            title: 'Amend In Root Folder',
            subtitle: 'Rename original files directly after permission.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _methodTile(
            mode: RenameOperationMode.duplicate,
            title: 'Clone And Work',
            subtitle: 'Create renamed copies and keep originals until replace.',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            label: 'Continue',
            onPressed: _continue,
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required RenameOperationMode mode,
    required String title,
    required String subtitle,
  }) {
    final selected = _mode == mode;
    return Card(
      child: ListTile(
        selected: selected,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: () => setState(() => _mode = mode),
      ),
    );
  }
}
