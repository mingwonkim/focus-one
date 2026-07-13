// lib/core/scene_decorations.dart
// 장면(숲/밤/바다)별 장식 요소 — 전부 시안(.dc.html)의 도형을 그대로 옮긴 것.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// 타이머 다이얼 안의 풍경. 좌표는 전부 지름 대비 비율 — 88px/216px 양쪽에서 동작.
class SceneDialPainter extends CustomPainter {
  SceneDialPainter(this.scene);

  final FocusScene scene;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // 배경 그라데이션
    final s = scene.style;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: s.dialColors,
          stops: s.dialStops,
        ).createShader(rect),
    );

    switch (scene) {
      case FocusScene.forest:
        _paintForest(canvas, d);
      case FocusScene.night:
        _paintNight(canvas, d);
      case FocusScene.ocean:
        _paintOcean(canvas, d);
    }
    canvas.restore();
  }

  // css bottom/left/width/height % → 캔버스 rect
  Rect _r(double d,
      {double? left, double? right, required double bottom, required double w, required double h}) {
    final x = left != null ? left * d : d - right! * d - w * d;
    final y = d - bottom * d - h * d;
    return Rect.fromLTWH(x, y, w * d, h * d);
  }

  void _radial(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0, 0.72],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _paintForest(Canvas canvas, double d) {
    final p = Paint();
    // 태양 글로우
    _radial(canvas, Offset(0.38 * d, 0.21 * d), 0.17 * d,
        const Color.fromRGBO(255, 246, 196, 0.95));
    // 먼 수풀 언덕
    p.color = const Color.fromRGBO(94, 199, 124, 0.8);
    canvas.drawOval(_r(d, left: -0.14, bottom: 0.26, w: 0.62, h: 0.44), p);
    p.color = const Color.fromRGBO(74, 184, 106, 0.8);
    canvas.drawOval(_r(d, right: -0.16, bottom: 0.24, w: 0.68, h: 0.48), p);
    // 나무 기둥
    p.color = const Color.fromRGBO(168, 121, 79, 0.85);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            _r(d, left: 0.30, bottom: 0.13, w: 0.038, h: 0.17),
            Radius.circular(0.016 * d)),
        p);
    p.color = const Color.fromRGBO(150, 104, 64, 0.85);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            _r(d, right: 0.27, bottom: 0.09, w: 0.043, h: 0.215),
            Radius.circular(0.021 * d)),
        p);
    // 가까운 수풀 언덕
    p.color = const Color.fromRGBO(48, 168, 86, 0.9);
    canvas.drawOval(_r(d, left: -0.20, bottom: -0.20, w: 0.78, h: 0.62), p);
    p.color = const Color.fromRGBO(36, 148, 72, 0.9);
    canvas.drawOval(_r(d, right: -0.18, bottom: -0.24, w: 0.84, h: 0.66), p);
    // 글자 가독용 베일
    _veil(canvas, d, const Color.fromRGBO(10, 60, 28, 0.28));
  }

  void _paintNight(Canvas canvas, double d) {
    final p = Paint();
    // 달 (글로우 → 본체 → 크레이터)
    final moonC = Offset(0.37 * d, 0.33 * d);
    final moonR = 0.172 * d;
    _radial(canvas, moonC, moonR * 1.5,
        const Color.fromRGBO(242, 217, 140, 0.28));
    canvas.drawCircle(
      moonC,
      moonR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.24, -0.32),
          colors: [Color(0xFFFDF3D0), Color(0xFFE0C47E)],
          stops: [0, 0.75],
        ).createShader(Rect.fromCircle(center: moonC, radius: moonR)),
    );
    p.color = const Color.fromRGBO(190, 158, 90, 0.45);
    canvas.drawCircle(moonC + Offset(-0.05 * d, 0.05 * d), 0.027 * d, p);
    p.color = const Color.fromRGBO(190, 158, 90, 0.4);
    canvas.drawCircle(moonC + Offset(0.045 * d, -0.02 * d), 0.019 * d, p);
    // 달 위의 토끼 (귀 2 + 머리 + 몸통)
    final rp = Paint()..color = const Color(0xFFF5F2EA);
    final earL = _rotRRect(moonC + Offset(-0.035 * d, -moonR - 0.055 * d),
        0.013 * d, 0.042 * d, -12);
    final earR = _rotRRect(moonC + Offset(0.0 * d, -moonR - 0.058 * d),
        0.013 * d, 0.045 * d, 8);
    canvas.drawPath(earL, rp);
    canvas.drawPath(earR, rp);
    rp.color = const Color(0xFFFAF7EF);
    canvas.drawOval(
        Rect.fromCenter(
            center: moonC + Offset(-0.015 * d, -moonR - 0.008 * d),
            width: 0.043 * d,
            height: 0.035 * d),
        rp);
    rp.color = const Color(0xFFF0EBDD);
    canvas.drawOval(
        Rect.fromCenter(
            center: moonC + Offset(-0.03 * d, -moonR + 0.014 * d),
            width: 0.07 * d,
            height: 0.04 * d),
        rp);
    // 별
    for (final (x, y, r, a) in [
      (0.78, 0.22, 0.013, 0.95),
      (0.70, 0.40, 0.008, 0.8),
      (0.54, 0.12, 0.011, 0.85),
      (0.16, 0.56, 0.008, 0.7),
    ]) {
      p.color = Color.fromRGBO(255, 244, 208, a);
      canvas.drawCircle(Offset(x * d, y * d), r * d, p);
    }
    // 어두운 언덕 실루엣
    p.color = const Color(0xFF0A0E1A);
    canvas.drawOval(_r(d, left: -0.16, bottom: -0.18, w: 0.74, h: 0.46), p);
    p.color = const Color(0xFF070A13);
    canvas.drawOval(_r(d, right: -0.14, bottom: -0.22, w: 0.80, h: 0.50), p);
  }

  void _paintOcean(Canvas canvas, double d) {
    final p = Paint();
    // 수면 빛줄기
    canvas.save();
    canvas.translate(0.42 * d, -0.1 * d);
    canvas.rotate(14 * math.pi / 180);
    final shaft = Rect.fromLTWH(0, 0, 0.14 * d, 0.7 * d);
    canvas.drawRect(
      shaft,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 255, 255, 0.55),
            Color.fromRGBO(255, 255, 255, 0),
          ],
        ).createShader(shaft),
    );
    canvas.restore();
    // 고래 (몸통 상/하 투톤 + 꼬리 + 눈)
    final body = _r(d, left: 0.24, bottom: 0.30, w: 0.47, h: 0.215);
    canvas.drawOval(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2B7DB4),
            Color(0xFF2B7DB4),
            Color(0xFFCFEAF8),
            Color(0xFFCFEAF8),
          ],
          stops: [0, 0.58, 0.585, 1],
        ).createShader(body),
    );
    p.color = const Color(0xFF2B7DB4);
    canvas.drawPath(
        _rotRRect(Offset(0.20 * d, body.top + 0.02 * d), 0.07 * d, 0.024 * d, 24,
            horizontal: true),
        p);
    canvas.drawPath(
        _rotRRect(Offset(0.20 * d, body.top + 0.075 * d), 0.065 * d, 0.024 * d,
            -14,
            horizontal: true),
        p);
    p.color = const Color(0xFF0E2F47);
    canvas.drawCircle(Offset(body.right - 0.03 * d, body.top + 0.11 * d),
        0.011 * d, p);
    // 물방울
    final bubble = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.011 * d;
    for (final (x, y, r, a) in [
      (0.78, 0.20, 0.021, 0.75),
      (0.70, 0.30, 0.013, 0.65),
      (0.72, 0.12, 0.016, 0.7),
    ]) {
      bubble.color = Color.fromRGBO(255, 255, 255, a);
      canvas.drawCircle(Offset(x * d, y * d), r * d, bubble);
    }
    // 모랫바닥
    p.style = PaintingStyle.fill;
    p.color = const Color.fromRGBO(232, 217, 184, 0.5);
    canvas.drawOval(_r(d, left: -0.10, bottom: -0.14, w: 0.70, h: 0.34), p);
    p.color = const Color.fromRGBO(214, 192, 148, 0.45);
    canvas.drawOval(_r(d, right: -0.12, bottom: -0.16, w: 0.76, h: 0.36), p);
    // 글자 가독용 베일
    _veil(canvas, d, const Color.fromRGBO(10, 45, 70, 0.3));
  }

  /// 중앙 시간 텍스트 가독용 radial 베일 (시안의 soft veil)
  void _veil(Canvas canvas, double d, Color color) {
    final c = Offset(0.5 * d, 0.44 * d);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, d, d),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.12),
          radius: 0.9,
          colors: [color, color.withValues(alpha: 0.03)],
          stops: const [0, 0.62],
        ).createShader(Rect.fromCircle(center: c, radius: d)),
    );
  }

  /// 회전된 알약(rrect) 경로 — 토끼 귀, 고래 꼬리 등
  Path _rotRRect(Offset topLeft, double w, double h, double deg,
      {bool horizontal = false}) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), Radius.circular(math.min(w, h) / 2));
    final m = Matrix4.identity()
      ..translateByDouble(topLeft.dx, topLeft.dy, 0, 1)
      ..rotateZ(deg * math.pi / 180);
    return (Path()..addRRect(r)).transform(m.storage);
  }

  @override
  bool shouldRepaint(SceneDialPainter old) => old.scene != scene;
}

/// 잎사귀 (border-radius: 0 62% 0 62% 회전) — 숲 장식/불릿
class Leaf extends StatelessWidget {
  const Leaf({
    super.key,
    required this.size,
    required this.colorA,
    required this.colorB,
    this.angle = 0,
    this.opacity = 1,
  });

  final double size;
  final Color colorA;
  final Color colorB;
  final double angle; // degrees
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorA, colorB],
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(size * 0.62),
              bottomLeft: Radius.circular(size * 0.62),
            ),
          ),
        ),
      ),
    );
  }
}

/// 십자 반짝이 별 — 밤 장식/불릿
class StarCross extends StatelessWidget {
  const StarCross({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bar = size * 0.16;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: (size - bar) / 2,
            child: Container(
              width: size,
              height: bar,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Positioned(
            left: (size - bar) / 2,
            child: Container(
              width: bar,
              height: size,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 파도 아치 (위쪽 반원 테두리) — 바다 장식/불릿
class WaveArc extends StatelessWidget {
  const WaveArc({
    super.key,
    required this.width,
    required this.color,
    this.strokeWidth = 3,
  });

  final double width;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width / 2),
      painter: _WaveArcPainter(color, strokeWidth),
    );
  }
}

class _WaveArcPainter extends CustomPainter {
  _WaveArcPainter(this.color, this.strokeWidth);
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawArc(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
          size.width - strokeWidth, size.height * 2 - strokeWidth),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_WaveArcPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// 작업 리스트 행의 불릿 — 잎 / 별 / 파도
class SceneBullet extends StatelessWidget {
  const SceneBullet({super.key, required this.scene, required this.selected});

  final FocusScene scene;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return switch (scene) {
      FocusScene.forest => Leaf(
          size: 10,
          angle: 45,
          colorA: selected ? const Color(0xFF5CD484) : const Color(0xFFA8DCB6),
          colorB: selected ? const Color(0xFF1F9E4C) : const Color(0xFF6BBD85),
        ),
      FocusScene.night => StarCross(
          size: 11,
          color: selected
              ? const Color.fromRGBO(242, 217, 140, 0.95)
              : const Color.fromRGBO(242, 217, 140, 0.5),
        ),
      FocusScene.ocean => WaveArc(
          width: 14,
          strokeWidth: 2,
          color: selected
              ? const Color.fromRGBO(31, 122, 181, 0.85)
              : const Color.fromRGBO(120, 190, 228, 0.8),
        ),
    };
  }
}

/// 확장 패널 상단 가로 장식 줄 (잎 덩굴 / 별 줄 / 파도 줄)
class SceneGarland extends StatelessWidget {
  const SceneGarland({super.key, required this.scene});

  final FocusScene scene;

  @override
  Widget build(BuildContext context) {
    final items = switch (scene) {
      FocusScene.forest => const [
          Leaf(size: 20, angle: 120, colorA: Color(0xFF7FD598), colorB: Color(0xFF3CB865), opacity: 0.7),
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Leaf(size: 14, angle: 60, colorA: Color(0xFFAEE8BF), colorB: Color(0xFF6ECF8D), opacity: 0.55),
          ),
          Leaf(size: 22, angle: 160, colorA: Color(0xFF6ECF8D), colorB: Color(0xFF2AA354), opacity: 0.75),
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Leaf(size: 13, angle: 30, colorA: Color(0xFFC4F0D1), colorB: Color(0xFF6ECF8D), opacity: 0.55),
          ),
          Leaf(size: 18, angle: 200, colorA: Color(0xFF7FD598), colorB: Color(0xFF35AD5E), opacity: 0.7),
        ],
      FocusScene.night => const [
          StarCross(size: 10, color: Color.fromRGBO(242, 217, 140, 0.7)),
          _GlowDot(size: 5, color: Color.fromRGBO(255, 244, 208, 0.55)),
          StarCross(size: 12, color: Color.fromRGBO(242, 217, 140, 0.8)),
          _GlowDot(size: 4, color: Color.fromRGBO(255, 244, 208, 0.5)),
          StarCross(size: 9, color: Color.fromRGBO(242, 217, 140, 0.65)),
        ],
      FocusScene.ocean => const [
          WaveArc(width: 22, color: Color.fromRGBO(85, 167, 216, 0.55)),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: WaveArc(width: 15, color: Color.fromRGBO(140, 205, 240, 0.5)),
          ),
          WaveArc(width: 24, color: Color.fromRGBO(70, 165, 221, 0.6)),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: WaveArc(width: 14, color: Color.fromRGBO(160, 215, 242, 0.5)),
          ),
          WaveArc(width: 20, color: Color.fromRGBO(85, 167, 216, 0.55)),
        ],
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

/// 미니 위젯 우상단 코너 장식
class MiniCornerAccents extends StatelessWidget {
  const MiniCornerAccents({super.key, required this.scene});

  final FocusScene scene;

  @override
  Widget build(BuildContext context) {
    return switch (scene) {
      FocusScene.forest => const Stack(children: [
          Positioned(
            top: -6,
            right: 14,
            child: Leaf(size: 26, angle: 140, colorA: Color(0xFF7FD598), colorB: Color(0xFF3CB865), opacity: 0.75),
          ),
          Positioned(
            top: 10,
            right: 34,
            child: Leaf(size: 16, angle: 200, colorA: Color(0xFFAEE8BF), colorB: Color(0xFF6ECF8D), opacity: 0.6),
          ),
        ]),
      FocusScene.night => const Stack(children: [
          Positioned(
            top: 12,
            right: 18,
            child: StarCross(size: 12, color: Color.fromRGBO(242, 217, 140, 0.8)),
          ),
          Positioned(
            top: 26,
            right: 38,
            child: _GlowDot(size: 7, color: Color.fromRGBO(255, 244, 208, 0.6)),
          ),
        ]),
      FocusScene.ocean => const Stack(children: [
          Positioned(
            top: 10,
            right: 16,
            child: WaveArc(width: 26, color: Color.fromRGBO(85, 167, 216, 0.6)),
          ),
          Positioned(
            top: 10,
            right: 39,
            child: WaveArc(width: 18, color: Color.fromRGBO(140, 205, 240, 0.6)),
          ),
        ]),
    };
  }
}

/// 시안의 그라데이션 원형 재생 버튼 (미니 48 / 확장 62)
class ScenePlayButton extends StatelessWidget {
  const ScenePlayButton({
    super.key,
    required this.style,
    required this.icon,
    required this.tooltip,
    this.size = 48,
    this.onTap,
  });

  final SceneStyle style;
  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [style.playGradA, style.playGradB],
              ),
              boxShadow: [
                BoxShadow(
                  color: style.playShadow,
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.2),
                ),
              ],
            ),
            child: Icon(icon, size: size * 0.46, color: style.playFg),
          ),
        ),
      ),
    );
  }
}

/// 시안의 고스트 원형 버튼 (↺ ⏭, 46px)
class SceneGhostButton extends StatelessWidget {
  const SceneGhostButton({
    super.key,
    required this.style,
    required this.icon,
    required this.tooltip,
    this.size = 46,
    this.onTap,
  });

  final SceneStyle style;
  final IconData icon;
  final String tooltip;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.ghostBg,
              border: Border.all(color: style.ghostBorder),
            ),
            child: Icon(icon, size: size * 0.42, color: style.ghostFg),
          ),
        ),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: size)],
      ),
    );
  }
}
