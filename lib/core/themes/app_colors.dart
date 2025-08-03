import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Minimalist brown theme
  static const Color primary = Color(0xFF8B4513); // Saddle Brown
  static const Color primaryDark = Color(0xFF654321); // Dark Brown
  static const Color primaryLight = Color(0xFFD2B48C); // Tan

  // Secondary colors - Warm accent
  static const Color secondary = Color(0xFFD2691E); // Chocolate
  static const Color secondaryDark = Color(0xFFA0522D); // Sienna
  static const Color secondaryLight = Color(0xFFF4A460); // Sandy Brown

  // Background colors - Light beige theme
  static const Color background = Color(0xFFF8F6F0); // Light beige for better contrast
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF5F3ED); // Slightly darker beige
  static const Color surfaceContainer =
      Color(0xFFF5F3ED); // Slightly darker beige 

  // Text colors - Brown theme
  static const Color onPrimary = Color(0xFFFFFFFF); // White on brown
  static const Color onSecondary = Color(0xFFFFFFFF); // White on brown
  static const Color onBackground = Color(0xFF3E2723); // Dark brown
  static const Color onSurface = Color(0xFF4E342E); // Brown
  static const Color onSurfaceVariant = Color(0xFF6D4C41); // Medium brown

  // Priority colors - Minimal color usage for emphasis only
  static const Color priorityLow = Color(0xFF8BC34A); // Light green
  static const Color priorityMedium = Color(0xFFFF9800); // Orange
  static const Color priorityHigh = Color(0xFFFF5722); // Deep orange
  static const Color priorityUrgent = Color(0xFFE53935); // Red

  // Status colors - Minimal color usage
  static const Color statusPending = Color(0xFF9E9E9E); // Gray
  static const Color statusInProgress = Color(0xFFFFA726); // Amber/Orange-Yellow
  static const Color statusCompleted = Color(0xFF4CAF50); // Green

  // Utility colors - Minimal usage
  static const Color error = Color(0xFFE53935); // Red
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color info = Color(0xFF2196F3); // Blue

  // Border and divider colors - Subtle browns
  static const Color border = Color(0xFFD7CCC8); // Light brown
  static const Color divider = Color(0xFFBCAAA4); // Medium brown

  // Gradient colors - Subtle brown gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B4513), Color(0xFFA0522D)], // Brown gradient
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F0)], // White to light beige
  );

  // Shadow colors - More defined for better card separation
  static const Color shadowLight = Color(0x10000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowStrong = Color(0x25000000);
}
