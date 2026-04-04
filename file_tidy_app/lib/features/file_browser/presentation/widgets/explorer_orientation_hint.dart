import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ExplorerOrientationHint extends StatelessWidget {
  const ExplorerOrientationHint({
    super.key,
    required this.onDismiss,
  });

  static const String _assetPath = 'assets/animations/rotate_your_phone.json';

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Lottie.asset(
                _assetPath,
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rotate for split view',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Turn your phone sideways to see folders and preview side by side.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
