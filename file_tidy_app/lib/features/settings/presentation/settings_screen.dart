import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plan: Free'),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Manage subscription',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'USB Archive tools',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.usbArchive),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: AppButton.primary(
                label: 'Logout',
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.signIn,
                  (route) => false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
