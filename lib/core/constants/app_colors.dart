import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Deep Medical Teal
  static const Color primary = Color(0xFF0B8FAC);
  static const Color primaryDark = Color(0xFF076880);
  static const Color primaryLight = Color(0xFF4DB6CC);
  static const Color primarySurface = Color(0xFFE0F4F8);

  // Secondary - Warm Coral
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9E9E);
  static const Color secondarySurface = Color(0xFFFFEEEE);

  // Accent - Soft Green (health)
  static const Color accent = Color(0xFF2ECC71);
  static const Color accentLight = Color(0xFF82E0AA);
  static const Color accentSurface = Color(0xFFE8F8F0);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F4F7);

  // Text
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF5A6B7C);
  static const Color textHint = Color(0xFFA0AFBE);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF2980B9);

  // Border
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = Color(0xFF0B8FAC);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0B8FAC), Color(0xFF076880)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0B8FAC), Color(0xFF1A6FA8), Color(0xFF0B5E8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark theme
  static const Color darkBackground = Color(0xFF0E1621);
  static const Color darkSurface = Color(0xFF1C2B3A);
  static const Color darkSurfaceVariant = Color(0xFF243448);
  static const Color darkBorder = Color(0xFF2D4055);
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF8FA3B3);
}
