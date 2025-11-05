import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary colors (Navy blue from design)
  static const Color primary = Color(0xFF8E2DE2);

  // Accent colors (Orange from logo)
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C69);
  static const Color accentDark = Color(0xFFE5521A);

  static const Color secondaryLight = Color(0xFF94A3B8);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color greyDark = Color(0xFF374151);

  // Text colors
  static const Color textPrimary = Color(0xFF101219);
  static const Color textSecondary = Color(0xFF101219);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF9CA3AF);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Background colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffold = Color(0xFFF8FAFC);

  // Input field colors
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputBorderFocused = Color(0xFF1E1B4B);

  // Card colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color smallCard = Color(0xFFF2F4F7);
  static const Color cardShadow = Color(0x1A000000);

  // Additional UI colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color backgroundSecondary = Color(0xFFF3F4F6);

  // Social button colors
  static const Color googleRed = Color(0xFFEA4335);
  static const Color appleBlack = Color(0xFF000000);
  static const Color linkedInBlue = Color(0xFF0077B5);

  // Gradient colors
  static const Color gradientPurple1 = Color(0xFF4A00E0);
  static const Color gradientPurple2 = Color(0xFF8E2DE2);
  static const Color gradientPurple3 = Color(0xFF6F22BC);
  static const Color gradientPurple4 = Color(0xFF03001E);

  // Gradient definitions
  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      gradientPurple1,
      gradientPurple2,
      gradientPurple3,
      gradientPurple4,
    ],
    stops: [0.0, 0.25, 0.63, 1.0],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      gradientPurple1,
      gradientPurple2,
      gradientPurple3,
      gradientPurple4,
    ],
    stops: [0.0, 0.25, 0.63, 1.0],
  );
}
