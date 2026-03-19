import 'package:flutter/material.dart';

class AppColorTokens {
  AppColorTokens._();

  static const primary = Color(0xFF00E5FF);
  static const primaryLight = Color(0xFF80F2FF);
  static const primaryDark = Color(0xFF005461);

  static const secondary = Color(0xFFFF00FF);
  static const secondaryLight = Color(0xFFFF72FF);
  static const secondaryDark = Color(0xFFB300B3);

  static const gold = Color(0xFFFFEA00);
  static const goldDark = Color(0xFFB2A300);

  static const purple = Color(0xFFB300B3);
  static const purpleLight = Color(0xFFFF72FF);

  static const bgPrimary = Color(0xFF000000);
  static const bgSecondary = Color(0xFF1C1C1E);
  static const bgTertiary = Color(0xFF162D28);

  static const surface = Color(0xFF000000);
  static const surfaceElevated = Color(0xFF4B4B52);

  static const border = Color(0xFF00E5FF);
  static const borderAccent = Color(0xFFA200FF);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF98989E);
  static const textDisabled = Color(0xFF606060);

  static const success = Color(0xFF00E676);
  static const warning = gold;
  static const error = Color(0xFFFF3B3B);
  static const info = primary;
}

@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  final Gradient primary;
  final Gradient secondary;
  final Gradient background;
  final Gradient card;
  final Gradient glow;

  const AppGradients({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.glow,
  });

  @override
  AppGradients copyWith({
    Gradient? primary,
    Gradient? secondary,
    Gradient? background,
    Gradient? card,
    Gradient? glow,
  }) {
    return AppGradients(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      card: card ?? this.card,
      glow: glow ?? this.glow,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primary: LinearGradient.lerp(
        primary as LinearGradient,
        other.primary as LinearGradient,
        t,
      )!,
      secondary: LinearGradient.lerp(
        secondary as LinearGradient,
        other.secondary as LinearGradient,
        t,
      )!,
      background: LinearGradient.lerp(
        background as LinearGradient,
        other.background as LinearGradient,
        t,
      )!,
      card: LinearGradient.lerp(
        card as LinearGradient,
        other.card as LinearGradient,
        t,
      )!,
      glow: LinearGradient.lerp(
        glow as LinearGradient,
        other.glow as LinearGradient,
        t,
      )!,
    );
  }

  static const dark = AppGradients(
    primary: LinearGradient(
      colors: [AppColorTokens.primary, AppColorTokens.primaryLight],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    secondary: LinearGradient(
      colors: [AppColorTokens.primary, AppColorTokens.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    background: LinearGradient(
      colors: [
        AppColorTokens.bgPrimary,
        AppColorTokens.bgTertiary,
        Color(0xFF173E49),
      ],
      stops: [0.0, 0.6, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    card: LinearGradient(
      colors: [AppColorTokens.bgSecondary, AppColorTokens.surface],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    glow: LinearGradient(
      colors: [AppColorTokens.primary, AppColorTokens.secondary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
  );
}

class AppColors {
  AppColors._();

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,

    // Primary — Electric Cyan
    primary: AppColorTokens.primary,
    onPrimary: Colors.black,
    primaryContainer: AppColorTokens.primaryDark,
    onPrimaryContainer: AppColorTokens.primaryLight,

    // Secondary — Pink/Magenta
    secondary: AppColorTokens.secondary,
    onSecondary: Colors.white,
    secondaryContainer: AppColorTokens.secondaryDark,
    onSecondaryContainer: AppColorTokens.secondaryLight,

    // Tertiary — Purple undertone
    tertiary: AppColorTokens.purple,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF2A1A4A),
    onTertiaryContainer: AppColorTokens.purpleLight,

    // Surfaces
    surface: AppColorTokens.surface,
    onSurface: AppColorTokens.textPrimary,
    surfaceContainerHighest: AppColorTokens.surfaceElevated,
    onSurfaceVariant: AppColorTokens.textSecondary,

    // Error
    error: AppColorTokens.error,
    onError: Colors.white,

    // Outline
    outline: AppColorTokens.border,
    outlineVariant: AppColorTokens.borderAccent,
  );
}
