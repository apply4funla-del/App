import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text('Sign in to sync settings and history securely.'),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: wide ? 280 : double.infinity,
                  child: AppButton.primary(
                    label: 'Continue',
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.connectorPicker),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: wide ? 280 : double.infinity,
                  child: AppButton.secondary(
                    label: 'Skip for now (Local mode)',
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.explorer),
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
