// lib/core/design_tokens.dart
import 'package:flutter/material.dart';

/// 디자인 토큰. 하드코딩 색상/매직넘버 금지 — 반드시 여기서 참조한다.
/// 디자인 언어: v2 — Tiimo 집중 화면 레퍼런스 + 링 안 장면 일러스트 (docs/v2/).
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

/// 장면별 스타일 값 — v2(Tiimo 레퍼런스) 팔레트. 근거: docs/v2/app-design-spec.md §3.
/// 작은 글자에 투명도 금지 — 전부 불투명 sRGB. 대비는 spec 표 참조(텍스트 ≥5:1).
class SceneStyle {
  const SceneStyle({
    required this.brightness,
    required this.cardBg,
    required this.cardBorder,
    required this.rowBg,
    required this.rowShadow,
    required this.textStrong,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.ringProgress,
    required this.ringTrack,
    required this.dialColors,
    required this.dialStops,
    required this.pillBg,
    required this.pillFg,
    required this.checkBg,
    required this.checkFg,
    required this.divider,
    required this.fieldFill,
    required this.sceneLabel,
    required this.footerLabel,
    required this.footerUnit,
  });

  final Brightness brightness;

  final Color cardBg; // 창 바탕
  final Color cardBorder; // 창 테두리 1px (창 외부 그림자 없음)
  final Color rowBg; // 리스트 카드·입력
  final Color? rowShadow; // 카드 그림자 (밤은 없음)

  final Color textStrong; // 제목·시간·작업
  final Color textMuted; // 라벨
  final Color textFaint; // 보조·완료

  final Color accent; // 작은 강조 글자·선택 테두리
  final Color ringProgress;
  final Color ringTrack;
  final List<Color> dialColors; // 링 안 풍경 하늘 그라데이션
  final List<double> dialStops;

  final Color pillBg; // 주 동작 알약 버튼
  final Color pillFg;
  final Color checkBg; // 완료 체크
  final Color checkFg;

  final Color divider;
  final Color fieldFill;

  final String sceneLabel; // 헤더 장면 칩 ("숲")
  final String footerLabel; // "오늘 심은 나무"
  final String footerUnit; // "그루"

  static const forest = SceneStyle(
    brightness: Brightness.light,
    cardBg: Color(0xFFEEF7F1),
    cardBorder: Color(0xFFDCEEE3),
    rowBg: Color(0xFFFFFFFF),
    rowShadow: Color(0x0F000000),
    textStrong: Color(0xFF162D22),
    textMuted: Color(0xFF405B4C),
    textFaint: Color(0xFF596C61),
    accent: Color(0xFF246B4B),
    ringProgress: Color(0xFF4F8D6D),
    ringTrack: Color(0xFFDCEEE3),
    dialColors: [
      Color(0xFFF0FFF4),
      Color(0xFFD2F7DC),
      Color(0xFF8FE2AB),
      Color(0xFF52C47C),
    ],
    dialStops: [0, 0.32, 0.66, 1],
    pillBg: Color(0xFF191B1A),
    pillFg: Color(0xFFFFFFFF),
    checkBg: Color(0xFF246B4B),
    checkFg: Color(0xFFFFFFFF),
    divider: Color(0xFFDCEEE3),
    fieldFill: Color(0xFFFFFFFF),
    sceneLabel: '숲',
    footerLabel: '오늘 심은 나무',
    footerUnit: '그루',
  );

  // 밤: spec은 라벤더(#C2B4ED)였으나 달·별 일러스트와 맞춰 달빛 골드 유지 — docs/v2/app-deviations.md
  static const night = SceneStyle(
    brightness: Brightness.dark,
    cardBg: Color(0xFF14131A),
    cardBorder: Color(0xFF2A2833),
    rowBg: Color(0xFF24222D),
    rowShadow: null,
    textStrong: Color(0xFFF6F3FC),
    textMuted: Color(0xFFCEC8DE),
    textFaint: Color(0xFFAAA6B8),
    accent: Color(0xFFE3C77F),
    ringProgress: Color(0xFFE3C77F),
    ringTrack: Color(0xFF3A3528),
    dialColors: [
      Color(0xFF232C4A),
      Color(0xFF171F38),
      Color(0xFF0D1222),
    ],
    dialStops: [0, 0.4, 1],
    pillBg: Color(0xFF34313F),
    pillFg: Color(0xFFFFFFFF),
    checkBg: Color(0xFFE3C77F),
    checkFg: Color(0xFF14131A),
    divider: Color(0xFF2A2833),
    fieldFill: Color(0xFF24222D),
    sceneLabel: '밤',
    footerLabel: '오늘 모은 별',
    footerUnit: '개',
  );

  static const ocean = SceneStyle(
    brightness: Brightness.light,
    cardBg: Color(0xFFEFF7FC),
    cardBorder: Color(0xFFDDEDF7),
    rowBg: Color(0xFFFFFFFF),
    rowShadow: Color(0x0F000000),
    textStrong: Color(0xFF142F40),
    textMuted: Color(0xFF405E70),
    textFaint: Color(0xFF536D79),
    accent: Color(0xFF246587),
    ringProgress: Color(0xFF568CAD),
    ringTrack: Color(0xFFDDEDF7),
    dialColors: [
      Color(0xFFEEF9FF),
      Color(0xFFC9E9F8),
      Color(0xFF7CBFE7),
      Color(0xFF3585BD),
    ],
    dialStops: [0, 0.3, 0.64, 1],
    pillBg: Color(0xFF191B1A),
    pillFg: Color(0xFFFFFFFF),
    checkBg: Color(0xFF246587),
    checkFg: Color(0xFFFFFFFF),
    divider: Color(0xFFDDEDF7),
    fieldFill: Color(0xFFFFFFFF),
    sceneLabel: '바다',
    footerLabel: '오늘 만난 고래',
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
  static const double lg = 16; // 리스트 카드·입력
  static const double xl = 24; // 창 (미니/확장/캡처)
  static const double full = 9999;
}

/// 컴포넌트 치수 (spec §1~2)
abstract class AppSize {
  static const double ringMini = 88; // 두께 12, 안쪽 여백 14
  static const double ringLarge = 160; // 두께 24, 안쪽 여백 28
  static const double ringCompact = 40; // 두께 6
  static const double control = 40; // 알약 높이·원형 버튼
  static const double controlSm = 32;
  static const double row = 56; // 작업 카드
  static const double chip = 32; // 카드 왼쪽 장면 칩
  static const double check = 24;
}

/// 리스트 카드 그림자 (Tiimo식 아주 옅은 6%) — 밤은 null
abstract class AppShadow {
  static List<BoxShadow>? card(Color? c) => c == null
      ? null
      : [BoxShadow(color: c, blurRadius: 8, offset: const Offset(0, 2))];
}

abstract class AppDuration {
  static const press = Duration(milliseconds: 80);
  static const release = Duration(milliseconds: 120);
  static const tab = Duration(milliseconds: 120);
  static const check = Duration(milliseconds: 160);
  static const tick = Duration(milliseconds: 300); // 링 진행 보간
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
