import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class UsbArchiveScreen extends StatelessWidget {
  const UsbArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Archive')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text('Use branded USB-C stick for easy archive/restore.'),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(label: 'Archive selected files', onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          AppButton.secondary(label: 'Restore from USB', onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          AppButton.primary(label: 'Verify copied files', onPressed: () {}),
        ],
      ),
    );
  }
}
