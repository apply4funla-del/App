import 'dart:io';

import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.item,
  });

  final FileItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return const Center(
        child: Text('Select a file to preview.'),
      );
    }

    if (item!.type == FileItemType.folder) {
      return const Center(
        child: Text('Folder selected. Choose a file to preview content.'),
      );
    }

    if (item!.type == FileItemType.pdf && item!.path != null) {
      final file = File(item!.path!);
      if (file.existsSync()) {
        return SfPdfViewer.file(file);
      }
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item!.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Source: ${item!.source.label}'),
              const SizedBox(height: AppSpacing.xs),
              Text('Type: ${item!.type.name}'),
              const SizedBox(height: AppSpacing.lg),
              const Expanded(
                child: Center(
                  child: Text(
                    'Preview placeholder.\nPDF viewer opens automatically for real file paths.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
