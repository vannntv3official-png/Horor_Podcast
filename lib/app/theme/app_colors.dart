import 'package:flutter/material.dart';

/// Design tokens for Khmer Horror Podcast:
/// Supports dual aesthetic:
/// 1. Light Mode: Soft Ivory & Deep Violet
/// 2. Dark Mode: Obsidian Midnight Gothic & Burnished Gold
class AppColors {
  // Light Backgrounds
  static const Color background = Color(0xFFFBF9F5);
  static const Color backgroundSecondary = Color(0xFFF3EFE6);
  static const Color surface = Color(0xFFFFFFFF);

  // Dark Backgrounds (Obsidian Gothic)
  static const Color darkBackground = Color(0xFF0C0714);
  static const Color darkBackgroundSecondary = Color(0xFF140D20);
  static const Color darkSurface = Color(0xFF1B1229);
  static const Color darkCardBg = Color(0xD9170E24); // 85% Obsidian Glass

  // Primary: Deep Violet / Midnight Purple
  static const Color primary = Color(0xFF1D102F);
  static const Color primaryLight = Color(0xFF2E1A47);
  static const Color primaryContainer = Color(0xFFEADBFF);

  // Dark Primary
  static const Color darkPrimary = Color(0xFFD6C6F5);
  static const Color darkPrimaryContainer = Color(0xFF2E1A47);

  // Secondary: Muted Lavender
  static const Color secondary = Color(0xFF6B587B);
  static const Color secondaryLight = Color(0xFFEDE8F5);
  static const Color darkSecondary = Color(0xFFB5ADC2);

  // Accent: Burnished Gold (Khmer Horror Brand Identity)
  static const Color accent = Color(0xFFC89B3C);
  static const Color accentLight = Color(0xFFF5E7C8);
  static const Color accentDark = Color(0xFFA17822);

  // Text colors (Light)
  static const Color textPrimary = Color(0xFF1A1523);
  static const Color textSecondary = Color(0xFF635C6E);
  static const Color textTertiary = Color(0xFF9B94A6);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Text colors (Dark)
  static const Color darkTextPrimary = Color(0xFFFBF8FF);
  static const Color darkTextSecondary = Color(0xFFB5ADC2);
  static const Color darkTextTertiary = Color(0xFF7E758C);

  // Glassmorphic Elements (Light)
  static const Color glassCardBg = Color(0xCCFFFFFF); // 80% opacity
  static const Color glassBorder = Color(0x338A7B9B); // subtle lavender border
  static const Color glassShadow = Color(0x0D1D102F); // 5% deep violet shadow
  static const Color glassHighlight = Color(0x40FFFFFF);

  // Glassmorphic Elements (Dark)
  static const Color darkGlassBorder = Color(0x33C89B3C); // subtle hairline gold
  static const Color darkGlassShadow = Color(0x66000000); // deep black drop shadow

  // Functional / Feedback
  static const Color error = Color(0xFFE04A4A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF388E3C);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFED6C02);
  static const Color warningContainer = Color(0xFFFFE0B2);

  // Divider & Outlines (Light)
  static const Color outline = Color(0xFFE2DCE9);
  static const Color outlineVariant = Color(0xFFEEEBF2);

  // Divider & Outlines (Dark)
  static const Color darkOutline = Color(0xFF2C223C);
  static const Color darkOutlineVariant = Color(0xFF382C4C);
}
