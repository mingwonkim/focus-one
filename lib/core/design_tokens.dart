// lib/core/design_tokens.dart
import 'package:flutter/material.dart';

/// 디자인 토큰. 하드코딩 색상/매직넘버 금지 — 반드시 여기서 참조한다.
/// 디자인 언어: 바탕화면 시안(FocusOne Forest/Night/Ocean .dc.html)이 원본.
abstract class AppColors {
  // 장면(FocusScene)과 무관한 공통 시맨틱 컬러
  static const onPrimary = Color(0xFFFFFFFF);
  static const error = Color(0xFFFF3B30); // iOS 레드
  static const success = Color(0xFF34C759); // iOS 그린
}

/// 화면 분위기 모드: 숲 / 밤 / 바다. 각 모드는 스타일 + 앰비언트 사운드를 가진다.
enum FocusScene {
  forest,
  night,
  ocean;

  SceneStyle get style => switch (this) {
        forest => SceneStyle.forest,
        night => SceneStyle.night,
        ocean => SceneStyle.ocean,
      };

  FocusScene get next =>
      FocusScene.values[(index + 1) % FocusScene.values.length];

  /// 앰비언트 사운드 애셋 경로 (forest.wav / night.wav / ocean.wav)
  String get soundAsset => 'sounds/$name.wav';
}

/// 장면별 스타일 값 — 전부 시안(.dc.html)에서 그대로 추출한 값이다. 임의 변경 금지.
class SceneStyle {
  const SceneStyle({
    required this.brightness,
    required this.cardBg,
    required this.cardBorder,
    required this.shadowColor,
    required this.heading,
    required this.textStrong,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.ringTrack,
    required this.timeColor,
    required this.timeShadow,
    required this.dialColors,
    required this.dialStops,
    required this.playGradA,
    required this.playGradB,
    required this.playFg,
    required this.playShadow,
    required this.ghostBg,
    required this.ghostBorder,
    required this.ghostFg,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeFg,
    required this.badgeText,
    required this.rowBg,
    required this.rowBorder,
    required this.rowSelBg,
    required this.rowSelBorder,
    required this.rowText,
    required this.rowDone,
    required this.divider,
    required this.fieldFill,
    required this.footerLabel,
    required this.footerEmoji,
    required this.footerUnit,
  });

  final Brightness brightness;

  // 카드 (미니 radius 30 / 확장 radius 36)
  final Color cardBg;
  final Color cardBorder;
  final Color shadowColor;

  // 텍스트
  final Color heading; // "FocusOne" 타이틀
  final Color textStrong; // 작업 제목
  final Color textMuted; // 라벨 (지금 집중할 일, 세션 라벨 …)
  final Color textFaint; // 보조 (🍅 카운트 …)

  // 타이머 링/다이얼
  final Color accent; // 진행 링
  final Color ringTrack;
  final Color timeColor;
  final Color timeShadow;
  final List<Color> dialColors; // 다이얼 안 풍경 배경 그라데이션
  final List<double> dialStops;

  // 재생 버튼 (그라데이션 원형)
  final Color playGradA;
  final Color playGradB;
  final Color playFg;
  final Color playShadow;

  // 고스트 버튼 (↺ ⏭)
  final Color ghostBg;
  final Color ghostBorder;
  final Color ghostFg;

  // 모드 뱃지 필
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeFg;
  final String badgeText;

  // 작업 리스트 행
  final Color rowBg;
  final Color rowBorder;
  final Color rowSelBg;
  final Color rowSelBorder;
  final Color rowText;
  final Color rowDone;

  final Color divider;
  final Color fieldFill;

  // 푸터 통계 ("오늘 심은 나무 🌲 2그루")
  final String footerLabel;
  final String footerEmoji;
  final String footerUnit;

  static const forest = SceneStyle(
    brightness: Brightness.light,
    cardBg: Color.fromRGBO(255, 255, 255, 0.86),
    cardBorder: Color.fromRGBO(255, 255, 255, 0.9),
    shadowColor: Color.fromRGBO(34, 120, 62, 0.18),
    heading: Color(0xFF14301C),
    textStrong: Color(0xFF16321E),
    textMuted: Color.fromRGBO(38, 84, 50, 0.55),
    textFaint: Color.fromRGBO(38, 84, 50, 0.45),
    accent: Color(0xFF2EB45C),
    ringTrack: Color.fromRGBO(46, 158, 80, 0.14),
    timeColor: Color(0xFFFFFFFF),
    timeShadow: Color.fromRGBO(16, 80, 38, 0.65),
    dialColors: [
      Color(0xFFF0FFF4),
      Color(0xFFD2F7DC),
      Color(0xFF8FE2AB),
      Color(0xFF52C47C),
    ],
    dialStops: [0, 0.32, 0.66, 1],
    playGradA: Color(0xFF3ECB6E),
    playGradB: Color(0xFF1F9E4C),
    playFg: Color(0xFFFFFFFF),
    playShadow: Color.fromRGBO(31, 158, 76, 0.4),
    ghostBg: Color.fromRGBO(46, 180, 92, 0.08),
    ghostBorder: Color.fromRGBO(46, 158, 80, 0.22),
    ghostFg: Color(0xFF2A9152),
    badgeBg: Color.fromRGBO(46, 180, 92, 0.12),
    badgeBorder: Color.fromRGBO(46, 180, 92, 0.3),
    badgeFg: Color(0xFF1F9E4C),
    badgeText: '🌿 숲 모드',
    rowBg: Color.fromRGBO(255, 255, 255, 0.7),
    rowBorder: Color.fromRGBO(46, 158, 80, 0.12),
    rowSelBg: Color.fromRGBO(46, 180, 92, 0.1),
    rowSelBorder: Color.fromRGBO(46, 180, 92, 0.45),
    rowText: Color(0xFF1C3A24),
    rowDone: Color.fromRGBO(38, 84, 50, 0.38),
    divider: Color.fromRGBO(46, 158, 80, 0.14),
    fieldFill: Color.fromRGBO(46, 158, 80, 0.08),
    footerLabel: '오늘 심은 나무',
    footerEmoji: '🌲',
    footerUnit: '그루',
  );

  static const night = SceneStyle(
    brightness: Brightness.dark,
    cardBg: Color.fromRGBO(20, 26, 40, 0.82),
    cardBorder: Color.fromRGBO(242, 217, 140, 0.22),
    shadowColor: Color.fromRGBO(0, 0, 0, 0.6),
    heading: Color(0xFFFDF3D0),
    textStrong: Color(0xFFF3EFE2),
    textMuted: Color.fromRGBO(242, 217, 140, 0.5),
    textFaint: Color.fromRGBO(242, 217, 140, 0.4),
    accent: Color(0xFFE8CF8E),
    ringTrack: Color.fromRGBO(242, 217, 140, 0.16),
    timeColor: Color(0xFFFDF3D0),
    timeShadow: Color.fromRGBO(0, 0, 0, 0.8),
    dialColors: [
      Color(0xFF232C4A),
      Color(0xFF171F38),
      Color(0xFF0D1222),
    ],
    dialStops: [0, 0.4, 1],
    playGradA: Color(0xFFF2D98C),
    playGradB: Color(0xFFCFA84E),
    playFg: Color(0xFF2A2210),
    playShadow: Color.fromRGBO(207, 168, 78, 0.35),
    ghostBg: Color.fromRGBO(242, 217, 140, 0.08),
    ghostBorder: Color.fromRGBO(242, 217, 140, 0.26),
    ghostFg: Color(0xFFE8CF8E),
    badgeBg: Color.fromRGBO(242, 217, 140, 0.1),
    badgeBorder: Color.fromRGBO(242, 217, 140, 0.32),
    badgeFg: Color(0xFFF2D98C),
    badgeText: '🌙 야간 모드',
    rowBg: Color.fromRGBO(255, 255, 255, 0.04),
    rowBorder: Color.fromRGBO(242, 217, 140, 0.12),
    rowSelBg: Color.fromRGBO(242, 217, 140, 0.1),
    rowSelBorder: Color.fromRGBO(242, 217, 140, 0.4),
    rowText: Color(0xFFF3EFE2),
    rowDone: Color.fromRGBO(243, 239, 226, 0.35),
    divider: Color.fromRGBO(242, 217, 140, 0.16),
    fieldFill: Color.fromRGBO(255, 255, 255, 0.06),
    footerLabel: '오늘 모은 별',
    footerEmoji: '⭐',
    footerUnit: '개',
  );

  static const ocean = SceneStyle(
    brightness: Brightness.light,
    cardBg: Color.fromRGBO(255, 255, 255, 0.86),
    cardBorder: Color.fromRGBO(255, 255, 255, 0.9),
    shadowColor: Color.fromRGBO(43, 125, 180, 0.18),
    heading: Color(0xFF0F2C42),
    textStrong: Color(0xFF10293C),
    textMuted: Color.fromRGBO(27, 83, 121, 0.55),
    textFaint: Color.fromRGBO(27, 83, 121, 0.45),
    accent: Color(0xFF2E8FCE),
    ringTrack: Color.fromRGBO(43, 134, 197, 0.14),
    timeColor: Color(0xFFFFFFFF),
    timeShadow: Color.fromRGBO(10, 50, 80, 0.7),
    dialColors: [
      Color(0xFFEEF9FF),
      Color(0xFFC9E9F8),
      Color(0xFF7CBFE7),
      Color(0xFF3585BD),
    ],
    dialStops: [0, 0.3, 0.64, 1],
    playGradA: Color(0xFF46A5DD),
    playGradB: Color(0xFF1F7AB5),
    playFg: Color(0xFFFFFFFF),
    playShadow: Color.fromRGBO(31, 122, 181, 0.4),
    ghostBg: Color.fromRGBO(46, 143, 206, 0.08),
    ghostBorder: Color.fromRGBO(46, 143, 206, 0.24),
    ghostFg: Color(0xFF2278B0),
    badgeBg: Color.fromRGBO(46, 143, 206, 0.1),
    badgeBorder: Color.fromRGBO(46, 143, 206, 0.3),
    badgeFg: Color(0xFF1F7AB5),
    badgeText: '🐋 바다 모드',
    rowBg: Color.fromRGBO(255, 255, 255, 0.7),
    rowBorder: Color.fromRGBO(46, 143, 206, 0.12),
    rowSelBg: Color.fromRGBO(46, 143, 206, 0.1),
    rowSelBorder: Color.fromRGBO(46, 143, 206, 0.45),
    rowText: Color(0xFF152F42),
    rowDone: Color.fromRGBO(27, 83, 121, 0.38),
    divider: Color.fromRGBO(46, 143, 206, 0.14),
    fieldFill: Color.fromRGBO(46, 143, 206, 0.08),
    footerLabel: '오늘 만난 고래',
    footerEmoji: '🐋',
    footerUnit: '마리',
  );
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
  static const double md = 10;
  static const double lg = 16; // 리스트 행
  static const double xl = 30; // 미니 위젯 카드
  static const double xxl = 36; // 확장 패널 카드
  static const double full = 9999;
}

/// 떠 있는 카드의 그림자 — 시안: 0 20px 50px + 0 2px 8px
abstract class AppShadow {
  static List<BoxShadow> floating(Color base) => [
        BoxShadow(
          color: base,
          blurRadius: 50,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: base.withValues(alpha: base.a * 0.45),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

abstract class AppDuration {
  static const micro = Duration(milliseconds: 150);
  static const enter = Duration(milliseconds: 200);
  static const transition = Duration(milliseconds: 280);
}

/// 미니 위젯 / 확장 패널 창 크기 규격 (시안 규격)
abstract class WindowSizes {
  static const mini = Size(320, 128);
  static const expanded = Size(400, 560);
  static const capture = Size(400, 180);
}
