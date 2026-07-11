// lib/core/design_tokens.dart
import 'package:flutter/material.dart';

/// 디자인 토큰. 하드코딩 색상/매직넘버 금지 — 반드시 여기서 참조한다.
abstract class AppColors {
  // Light
  static const primary = Color(0xFF6C5CE7); // 차분한 보라 — 집중/안정
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF8F9FA);
  static const onSurface = Color(0xFF1A1A1A);
  static const onSurfaceVariant = Color(0xFF6B7280);
  static const outline = Color(0xFFE5E7EB);
  static const error = Color(0xFFDC2626);
  static const success = Color(0xFF16A34A);

  // Dark
  static const surfaceDark = Color(0xFF1A1A1A);
  static const backgroundDark = Color(0xFF121212);
  static const onSurfaceDark = Color(0xFFE5E7EB);
  static const onSurfaceVariantDark = Color(0xFF9CA3AF);
  static const outlineDark = Color(0xFF374151);
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double full = 9999;
}

abstract class AppDuration {
  static const micro = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 200);
  static const transition = Duration(milliseconds: 280);
}

/// 미니 위젯 / 확장 패널 창 크기 규격
abstract class WindowSizes {
  static const mini = Size(320, 128);
  static const expanded = Size(400, 580);
  static const capture = Size(400, 180);
}
