// lib/core/app_theme.dart
import 'package:flutter/material.dart';
import 'design_tokens.dart';

abstract class AppTheme {
  static ThemeData get light => _base(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          error: AppColors.error,
        ),
        scaffoldBackground: Colors.transparent,
      );

  static ThemeData get dark => _base(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.onSurfaceDark,
          onSurfaceVariant: AppColors.onSurfaceVariantDark,
          outline: AppColors.outlineDark,
          error: AppColors.error,
        ),
        scaffoldBackground: Colors.transparent,
      );

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // frameless 창의 라운드 코너를 위해 Scaffold는 투명 처리
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.4),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
