import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/components/onboarding_screen.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final wide = width >= 720;
    final compact = width < 380;
    final buttonWidth = wide ? 360.0 : width.clamp(220.0, 360.0);
    final logoSize = wide ? 72.0 : 64.0;

    return OnboardingScreen(
      onBack: () => Navigator.of(context).maybePop(),
      child: Column(
        children: [
          if (wide) const SizedBox(height: AppSpacing.sm),
          Image.asset(
            AppAssets.logoWordmark,
            width: wide ? 240 : width.clamp(180.0, 230.0),
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: buttonWidth),
            child: Column(
              children: [
                OnboardingAssetButton(
                  assetPath: AppAssets.useForFreeButton,
                  semanticLabel: 'Use for free',
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.connectorPicker,
                    (route) => false,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OnboardingAssetButton(
                  assetPath: AppAssets.signUpButton,
                  semanticLabel: 'Sign up',
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.signIn,
                    arguments: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sign up to manage Google Drive and Dropbox.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: compact ? AppSpacing.sm : AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _LogoBubble(assetPath: AppAssets.dropboxLogo, size: logoSize),
              _LogoBubble(assetPath: AppAssets.googleDriveLogo, size: logoSize),
              _LogoBubble(assetPath: AppAssets.phoneLogo, size: logoSize),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
          Text(
            'You agree to the Tidily Privacy Policy when creating an account.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LogoBubble extends StatelessWidget {
  const _LogoBubble({
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
