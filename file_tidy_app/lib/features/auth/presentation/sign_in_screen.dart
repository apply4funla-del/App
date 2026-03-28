import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Sign in to sync settings and history securely.'),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: 'Continue',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.connectorPicker),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              label: 'Skip for now (Local mode)',
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.explorer),
            ),
          ],
        ),
      ),
    );
  }
}
