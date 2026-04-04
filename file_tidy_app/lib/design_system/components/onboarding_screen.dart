import 'package:file_tidy_app/design_system/tokens/app_assets.dart';
import 'package:file_tidy_app/design_system/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    this.title,
    required this.child,
    this.onBack,
    this.maxWidth = 560,
  });

  final String? title;
  final Widget child;
  final VoidCallback? onBack;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 720 ? AppSpacing.lg : AppSpacing.md;
            final verticalPadding = width >= 720 ? AppSpacing.md : AppSpacing.sm;
            final topBarHeight = width >= 720 ? 64.0 : 56.0;
            final titleStyle =
                width >= 420 ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.titleLarge;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: constraints.maxHeight - (verticalPadding * 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: topBarHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (onBack != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: onBack,
                                  child: Image.asset(
                                    AppAssets.backButton,
                                    width: width >= 420 ? 46 : 40,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            if (title != null)
                              Center(
                                child: Text(
                                  title!,
                                  textAlign: TextAlign.center,
                                  style: titleStyle,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
