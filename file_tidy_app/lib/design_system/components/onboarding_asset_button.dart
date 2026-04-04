import 'package:flutter/material.dart';

class OnboardingAssetButton extends StatelessWidget {
  const OnboardingAssetButton({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    required this.onPressed,
    this.width,
  });

  final String assetPath;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget child = Image.asset(
      assetPath,
      width: width,
      fit: BoxFit.contain,
    );

    if (onPressed == null) {
      child = Opacity(
        opacity: 0.45,
        child: child,
      );
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
