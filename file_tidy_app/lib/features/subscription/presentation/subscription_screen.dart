import 'package:file_tidy_app/app/app_router.dart';
import 'package:file_tidy_app/app/dependency_container.dart';
import 'package:file_tidy_app/core/use_cases/get_current_user_use_case.dart';
import 'package:file_tidy_app/design_system/components/onboarding_asset_button.dart';
import 'package:file_tidy_app/design_system/services/button_press_feedback.dart';
import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _dependencies = DependencyContainer.instance;

  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  String? _email;
  bool _loading = true;
  _SubscriptionChoice _selectedChoice = _SubscriptionChoice.annual;

  @override
  void initState() {
    super.initState();
    _getCurrentUserUseCase = GetCurrentUserUseCase(_dependencies.appAuthRepository);
    _load();
  }

  Future<void> _load() async {
    final currentUser = await _getCurrentUserUseCase();
    if (!mounted) {
      return;
    }
    setState(() {
      _email = currentUser?.email;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width >= 720 ? 420.0 : width.clamp(260.0, 360.0);

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      minHeight: MediaQuery.sizeOf(context).height - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: width >= 420 ? 56 : 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: ButtonPressFeedback.wrap(() => Navigator.of(context).maybePop()),
                              child: Image.asset(
                                AppAssets.backButton,
                                width: width >= 420 ? 46 : 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Subscription',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.black,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: _SelectablePlanCard(
                            assetPath: AppAssets.freePlanCard,
                            selected: _selectedChoice == _SubscriptionChoice.free,
                            onTap: () {
                              setState(() => _selectedChoice = _SubscriptionChoice.free);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: _SelectablePlanCard(
                            assetPath: AppAssets.subscribePlanCard,
                            selected: _selectedChoice == _SubscriptionChoice.annual,
                            onTap: () {
                              setState(() => _selectedChoice = _SubscriptionChoice.annual);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: Image.asset(
                            AppAssets.subscriptionCommitment,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: OnboardingAssetButton(
                            assetPath: AppAssets.subscribeButton,
                            semanticLabel: 'Subscribe',
                            onPressed: () {
                              if (_selectedChoice == _SubscriptionChoice.free) {
                                Navigator.of(context).maybePop();
                                return;
                              }
                              if (_email == null) {
                                Navigator.of(context).pushNamed(AppRoutes.signUp);
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Subscription checkout comes next.'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

enum _SubscriptionChoice { free, annual }

class _SelectablePlanCard extends StatelessWidget {
  const _SelectablePlanCard({
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: selected ? AppColors.brandDark : Colors.transparent,
          width: 3,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: ButtonPressFeedback.wrap(onTap),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          width: double.infinity,
        ),
      ),
    );
  }
}
