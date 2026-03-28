import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/app_button.dart';
import 'package:file_tidy_app/design_system/components/lottie_slot.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const LottieSlot(fallbackIcon: Icons.auto_fix_high_outlined),
              const SizedBox(height: AppSpacing.lg),
              Text('Clean file names fast', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Browse folders, preview files, and rename with manual control or AI suggestions.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  label: 'Get Started',
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
