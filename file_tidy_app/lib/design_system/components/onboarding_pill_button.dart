import 'package:file_tidy_app/design_system/services/button_press_feedback.dart';
import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';

enum OnboardingPillTone { green, blue, white }

class OnboardingPillButton extends StatelessWidget {
  const OnboardingPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = OnboardingPillTone.green,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final OnboardingPillTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      OnboardingPillTone.green => AppColors.brand,
      OnboardingPillTone.blue => AppColors.accentBlue,
      OnboardingPillTone.white => AppColors.surface,
    };
    final foreground = tone == OnboardingPillTone.white ? AppColors.ink : Colors.white;
    final border = tone == OnboardingPillTone.white ? AppColors.border : background.withValues(alpha: 0.9);
    final height = compact ? 48.0 : 72.0;
    final fontSize = compact ? 22.0 : 28.0;

    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: ButtonPressFeedback.wrap(onPressed),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: compact ? 14 : 18,
                  top: compact ? 10 : 12,
                  child: Row(
                    children: [
                      _dot(size: compact ? 9 : 12),
                      const SizedBox(width: 8),
                      _dot(size: compact ? 6 : 8),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 28),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w400,
                            color: foreground,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
