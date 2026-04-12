import 'package:eagle_esports/core/theme/app_colors.dart';
import 'package:eagle_esports/core/theme/app_components.dart';
import 'package:eagle_esports/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppThemes {
  AppThemes._();

  // ================= DARK THEME =================
  static ThemeData dark() {
    final scheme = AppColors.darkColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,

      // Backgrounds derive from scheme
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,

      // Typography (theme-aware)
      textTheme: AppTypography.themed(scheme),
      fontFamily: AppTypography.primaryFont,

      // Component themes
      elevatedButtonTheme: AppComponents.elevated(scheme),
      outlinedButtonTheme: AppComponents.outlined(scheme),
      inputDecorationTheme: AppComponents.input(scheme),
      cardTheme: AppComponents.card(scheme),
      dividerTheme: AppComponents.divider(scheme),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.themed(scheme).titleLarge,
      ),

      // Progress
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: AppTypography.themed(scheme).bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(scheme.primary),
        trackColor: WidgetStateProperty.all(
          scheme.primary.withValues(alpha: 0.4),
        ),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(scheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // Theme extensions (gradients, etc.)
      extensions: const [AppGradients.dark],
    );
  }
}
