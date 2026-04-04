import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/models/file_item.dart';
import 'package:file_tidy_app/core/use_cases/get_subscription_status_use_case.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/components/onboarding_screen.dart';
import 'package:file_tidy_app/design_system/services/button_press_feedback.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class MethodScreen extends StatefulWidget {
  const MethodScreen({
    super.key,
    required this.source,
  });

  final FileSource source;

  @override
  State<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends State<MethodScreen> {
  final _dependencies = DependencyContainer.instance;
  String? _selectedAction;

  Future<void> _continue() async {
    if (_selectedAction == 'tidy') {
      Navigator.of(context).pushNamed(
        AppRoutes.tidyMethod,
        arguments: widget.source,
      );
      return;
    }
    if (_selectedAction == 'archive') {
      final subscription = await GetSubscriptionStatusUseCase(
        _dependencies.subscriptionRepository,
      )();
      if (!mounted) {
        return;
      }
      if (!subscription.canUseUsbArchive) {
        Navigator.of(context).pushNamed(AppRoutes.subscription);
        return;
      }
      Navigator.of(context).pushNamed(AppRoutes.usbArchive);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 720;
    final buttonWidth = wide ? 260.0 : width.clamp(220.0, 320.0);
    return OnboardingScreen(
      title: 'Method',
      onBack: () => Navigator.of(context).maybePop(),
      maxWidth: 760,
      child: Column(
        children: [
          Text(
            'Choose what you want to do next.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _methodTile(
            id: 'archive',
            assetPath: AppAssets.archiveOptionCard,
          ),
          const SizedBox(height: AppSpacing.md),
          _methodTile(
            id: 'tidy',
            assetPath: AppAssets.manageFileOptionCard,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: buttonWidth,
            child: OnboardingAssetButton(
              assetPath: AppAssets.nextButton,
              semanticLabel: 'Next',
              onPressed: _selectedAction == null ? null : _continue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String id,
    required String assetPath,
  }) {
    final selected = _selectedAction == id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: selected ? AppColors.brandDark : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: ButtonPressFeedback.wrap(() => setState(() => _selectedAction = id)),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}
