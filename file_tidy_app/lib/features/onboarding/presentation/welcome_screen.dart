import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: wide ? AppSpacing.lg : AppSpacing.sm),
                  Image.asset(
                    AppAssets.logoWordmark,
                    width: wide ? 360 : width.clamp(220, 320),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Manage your life and memories.',
                    textAlign: TextAlign.center,
                    style: wide
                        ? Theme.of(context).textTheme.headlineLarge
                        : Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: wide ? 340 : 260,
                    child: Lottie.asset(
                      AppAssets.heroAnimation,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: wide ? 360 : 420),
                    child: OnboardingAssetButton(
                      assetPath: AppAssets.continueButton,
                      semanticLabel: 'Continue',
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.signUp),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
