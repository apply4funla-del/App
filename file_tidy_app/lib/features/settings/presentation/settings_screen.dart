import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          children: [
            Text('How Your Data Is Handled', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('Only folders you choose are processed.'),
            const SizedBox(height: AppSpacing.xs),
            const Text('AI uses minimal snippets only when AI assist is enabled.'),
            const SizedBox(height: AppSpacing.xs),
            const Text('Nothing is silently scanned across all accounts.'),
            const SizedBox(height: AppSpacing.lg),
            Text('Controls', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'USB Archive tools',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.usbArchive),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Delete my app data',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
