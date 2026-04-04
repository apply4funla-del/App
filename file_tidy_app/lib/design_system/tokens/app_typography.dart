import 'package:file_tidy_app/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  static TextTheme theme() {
    return GoogleFonts.robotoTextTheme().copyWith(
      headlineLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.08,
        color: AppColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.12,
        color: AppColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.24,
        color: AppColors.ink,
      ),
      titleSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: AppColors.inkMuted,
      ),
      bodySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.inkMuted,
      ),
      labelLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}
