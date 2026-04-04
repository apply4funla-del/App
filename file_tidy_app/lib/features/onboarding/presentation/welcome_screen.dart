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
    final screenSize = MediaQuery.sizeOf(context);
    final width = screenSize.width;
    final height = screenSize.height;
    final wide = width >= 720;
    final horizontalPadding = wide ? AppSpacing.xl : AppSpacing.md;
    final logoWidth = wide ? 360.0 : width.clamp(220.0, 320.0);
    final heroHeight = wide ? (height * 0.36).clamp(260.0, 360.0) : (height * 0.28).clamp(180.0, 280.0);
    final buttonWidth = wide ? 360.0 : width.clamp(220.0, 360.0);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: width >= 420 ? AppSpacing.lg : AppSpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: wide ? 760 : 420,
                minHeight: height - 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: wide ? AppSpacing.lg : AppSpacing.sm),
                  Image.asset(
                    AppAssets.logoWordmark,
                    width: logoWidth,
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
                    height: heroHeight,
                    child: Lottie.asset(
                      AppAssets.heroAnimation,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: buttonWidth),
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
