import 'package:file_tidy_app/core/models/usb_archive_execution_result.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class ArchiveStepCard extends StatelessWidget {
  const ArchiveStepCard({
    super.key,
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

class ArchiveSelectionTile extends StatelessWidget {
  const ArchiveSelectionTile({
    super.key,
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

class ArchiveResultCard extends StatelessWidget {
  const ArchiveResultCard({
    super.key,
    required this.result,
    required this.removedFromPhoneMode,
  });

  final UsbArchiveExecutionResult result;
  final bool removedFromPhoneMode;

  @override
  Widget build(BuildContext context) {
    return ArchiveStepCard(
      title: 'Archive result',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Copied: ${result.copiedCount}'),
          Text('Verified: ${result.verifiedCount}'),
          Text('Renamed copies: ${result.renamedCopyCount}'),
          Text('Replaced old files: ${result.replacedCount}'),
          Text('Failed: ${result.failedCount}'),
          if (removedFromPhoneMode) Text('Removed from phone: ${result.removedOriginalCount}'),
        ],
      ),
    );
  }
}

class ArchivePrimaryAction extends StatelessWidget {
  const ArchivePrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButton.primary(
        label: label,
        onPressed: onPressed,
      ),
    );
  }
}
