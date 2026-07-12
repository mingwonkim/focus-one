// lib/core/design_tokens.dart
import 'package:flutter/material.dart';

/// 디자인 토큰. 하드코딩 색상/매직넘버 금지 — 반드시 여기서 참조한다.
/// 디자인 언어: Apple HIG 기반 — iOS 시스템 팔레트, 헤어라인, 필 형태, 절제된 그림자.
abstract class AppColors {
  // Light (iOS 시스템 컬러 기반)
  static const primary = Color(0xFF007AFF); // iOS 블루
  static const onPrimary = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F7); // Apple 라이트 그레이
  static const onSurface = Color(0xFF1D1D1F); // Apple 텍스트 블랙
  static const onSurfaceVariant = Color(0xFF86868B); // Apple 세컨더리
  static const outline = Color(0xFFD2D2D7); // 헤어라인
  static const fieldFill = Color(0xFFF2F2F7); // 입력 필드 배경 (iOS 검색창)
  static const error = Color(0xFFFF3B30); // iOS 레드
  static const success = Color(0xFF34C759); // iOS 그린

  // Dark
  static const surfaceDark = Color(0xFF1D1D1F);
  static const backgroundDark = Color(0xFF000000);
  static const onSurfaceDark = Color(0xFFF5F5F7);
  static const onSurfaceVariantDark = Color(0xFF98989D);
  static const outlineDark = Color(0xFF38383A);
  static const fieldFillDark = Color(0xFF2C2C2E);
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
  static const double md = 10; // iOS 필드/버튼 기본
  static const double lg = 14;
  static const double xl = 20; // 카드/창 코너
  static const double full = 9999;
}

/// 떠 있는 카드의 그림자 — 크고 부드럽고 옅게 (Apple 스타일)
abstract class AppShadow {
  static List<BoxShadow> floating(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: base.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
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
