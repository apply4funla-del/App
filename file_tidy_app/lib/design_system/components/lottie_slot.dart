import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieSlot extends StatelessWidget {
  const LottieSlot({
    super.key,
    this.assetPath,
    this.width = 120,
    this.height = 120,
    this.fallbackIcon = Icons.auto_awesome,
  });

  final String? assetPath;
  final double width;
  final double height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null) {
      return Icon(fallbackIcon, size: width * 0.58);
    }

    return Lottie.asset(
      assetPath!,
      width: width,
      height: height,
      repeat: true,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, size: width * 0.58),
    );
  }
}
