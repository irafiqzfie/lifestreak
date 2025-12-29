import 'package:flutter/material.dart';

class AppColors {
  // Dark Mode Backgrounds
  static const darkBackground = Color(0xFF121412);
  static const darkSurface = Color(0xFF1A1D1A);
  static const darkCard = Color(0xFF1C201C);
  static const darkDivider = Color(0xFF2A2F2A);

  // Dark Mode Text - Improved contrast for readability
  static const textPrimary = Color(0xFFF0F4F0);
  static const textSecondary = Color(0xFFB8C4B8);
  static const textMuted = Color(0xFF8A9A8A);

  // Brand Green
  static const greenPrimary = Color(0xFF3F7A4F);
  static const greenStrong = Color(0xFF5FA874);
  static const greenSoft = Color(0xFF2F5D3A);

  // Light Mode (existing)
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightDivider = Color(0xFFE5E7EB);
  
  static const lightTextPrimary = Color(0xFF0D1B13);
  static const lightTextSecondary = Color(0xFF6B7280);

  // Heatmap intensity mapping
  static Color heatmapColor(int score, bool isDark) {
    if (isDark) {
      switch (score) {
        case 0:
          return const Color(0xFF252825); // Lighter than darkSurface for better visibility
        case 1:
          return const Color(0xFF3D6647);
        case 2:
          return const Color(0xFF4A8F5E);
        case 3:
          return const Color(0xFF5FA874);
        default:
          return const Color(0xFF252825);
      }
    } else {
      // Light mode heatmap colors
      switch (score) {
        case 0:
          return const Color(0xFFEBEEEB);
        case 1:
          return const Color(0xFFC6E6D0);
        case 2:
          return const Color(0xFF7FBC92);
        case 3:
          return const Color(0xFF3F7A4F);
        default:
          return const Color(0xFFEBEEEB);
      }
    }
  }
}
