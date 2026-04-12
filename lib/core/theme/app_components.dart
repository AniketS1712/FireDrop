import 'package:eagle_esports/core/theme/app_sizes.dart';
import 'package:eagle_esports/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppComponents {
  AppComponents._();

  // ================= ELEVATED BUTTON =================
  static ElevatedButtonThemeData elevated(ColorScheme scheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, AppSizes.buttonMd)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppSizes.space24),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => scheme.onSurface.withAlpha(24),
        ),
        foregroundColor: WidgetStateProperty.all(scheme.onPrimary),
        elevation: WidgetStateProperty.all(AppSizes.elevation1),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.base.labelLarge),
      ),
    );
  }

  // ================= OUTLINED BUTTON =================
  static OutlinedButtonThemeData outlined(ColorScheme scheme) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, AppSizes.buttonSm)),
        foregroundColor: WidgetStateProperty.all(scheme.primary),
        side: WidgetStateProperty.all(BorderSide(color: scheme.primary)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radius16),
            side: BorderSide(color: scheme.primary, width: 2),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.base.labelLarge),
      ),
    );
  }

  // ================= INPUT FIELD =================
  static InputDecorationTheme input(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.space16,
        vertical: AppSizes.space16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      hintStyle: AppTypography.base.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  // ================= CARD =================
  static CardThemeData card(ColorScheme scheme) {
    return CardThemeData(
      color: scheme.surface,
      elevation: AppSizes.elevation1,
      margin: const EdgeInsets.all(AppSizes.space8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius16),
      ),
    );
  }

  // ================= DIVIDER =================
  static DividerThemeData divider(ColorScheme scheme) {
    return DividerThemeData(
      color: scheme.outline,
      thickness: 1.0,
      space: AppSizes.space16,
    );
  }
}
