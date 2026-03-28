import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:file_tidy_app/features/preview/presentation/preview_pane.dart';
import 'package:flutter/material.dart';

class FilePreviewScreen extends StatelessWidget {
  const FilePreviewScreen({
    super.key,
    required this.item,
    required this.onRenamePressed,
    required this.onTidyUpPressed,
  });

  final FileItem item;
  final VoidCallback onRenamePressed;
  final VoidCallback onTidyUpPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Column(
        children: [
          Expanded(child: PreviewPane(item: item)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Tidy Up',
                    onPressed: onTidyUpPressed,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton.primary(
                    label: 'Rename',
                    onPressed: onRenamePressed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
