import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:file_tidy_app/design_system/tokens/app_radii.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : isPrimary = true;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
  }) : isPrimary = false;

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: isPrimary ? AppColors.brand : AppColors.surface,
      foregroundColor: isPrimary ? Colors.white : AppColors.ink,
      side: isPrimary ? null : const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );

    return FilledButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}
