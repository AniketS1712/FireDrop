import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // ================= FONT FAMILIES =================
  static const String primaryFont = 'Manrope';
  static const String displayFont = 'Orbitron';

  // ================= BASE TEXT THEME =================
  static const TextTheme base = TextTheme(
    // ===== DISPLAY (Brand / Hero only) =====
    displayLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      height: 1.2,
    ),

    displayMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),

    displaySmall: TextStyle(
      fontFamily: displayFont,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),

    // ===== HEADLINES (Screen-level importance) =====
    headlineLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),

    headlineMedium: TextStyle(
      fontFamily: displayFont,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),

    headlineSmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),

    // ===== TITLES (Component-level importance) =====
    titleLarge: TextStyle(
      fontFamily: primaryFont,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),

    titleMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),

    titleSmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),

    // ===== BODY (Content text) =====
    bodyLarge: TextStyle(
      fontFamily: primaryFont,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),

    bodyMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),

    bodySmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),

    // ===== LABELS (Content text) =====
    labelLarge: TextStyle(
      fontFamily: displayFont,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      height: 1.3,
    ),

    labelMedium: TextStyle(
      fontFamily: primaryFont,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),

    labelSmall: TextStyle(
      fontFamily: primaryFont,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
  );

  // ================= THEME-AWARE TEXT THEME =================
  static TextTheme themed(ColorScheme scheme) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: scheme.onSurface),
      displayMedium: base.displayMedium?.copyWith(color: scheme.onSurface),
      displaySmall: base.displaySmall?.copyWith(color: scheme.onSurface),

      headlineLarge: base.headlineLarge?.copyWith(color: scheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(color: scheme.onSurface),
      headlineSmall: base.headlineSmall?.copyWith(color: scheme.onSurface),

      titleLarge: base.titleLarge?.copyWith(color: scheme.onSurface),
      titleMedium: base.titleMedium?.copyWith(color: scheme.onSurface),
      titleSmall: base.titleSmall?.copyWith(color: scheme.onSurface),

      bodyLarge: base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurface),

      labelLarge: base.labelLarge?.copyWith(color: scheme.onSurface),
      labelMedium: base.labelMedium?.copyWith(color: scheme.onSurface),
      labelSmall: base.labelSmall?.copyWith(color: scheme.onSurface),
    );
  }
}
