import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definition supporting authentic Khmer scripts & Latin characters.
class AppTypography {
  static TextStyle get baseKhmer => GoogleFonts.kantumruyPro(
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      );

  static TextTheme get textTheme {
    final base = baseKhmer;
    return TextTheme(
      displayLarge: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: AppColors.primary,
      ),
      displayMedium: base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: AppColors.primary,
      ),
      displaySmall: base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: AppColors.primary,
      ),
      headlineMedium: base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      headlineSmall: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      titleLarge: base.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      ),
      titleMedium: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: AppColors.textPrimary,
      ),
      titleSmall: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: AppColors.textSecondary,
      ),
      bodyLarge: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.55,
        color: AppColors.textPrimary,
      ),
      bodyMedium: base.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        height: 1.45,
        color: AppColors.textTertiary,
      ),
      labelLarge: base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      ),
      labelMedium: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.textSecondary,
      ),
      labelSmall: base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.textTertiary,
      ),
    );
  }
}
