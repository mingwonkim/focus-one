// lib/mobile/focus/scene_fill.dart
// 집중 중 화면 전체 변화: 바다 파도 · 숲이 물들며 자람 · 밤 해질녘에서 우주로 · 일상 아이스 아메리카노.
// 높이는 남은 시간(시계)에서만 나온다. 움직임은 약 24fps로 제한하고 앱이 안 보이면 멈춘다.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// 수면 y. p=0이면 화면 바닥이라 시작하자마자 보이고, p=1이면 화면 위로 [overshoot]만큼
/// 넘겨 물결 골이 비지 않는다. [overshoot]는 물결 폭만큼만 — 크면 끝나기 전에 가득 찬다.
double fillSurfaceY(double height, double p, {double overshoot = 0}) =>
    height - p.clamp(0.0, 1.0) * (height + overshoot);

class SceneFill extends StatefulWidget {
  const SceneFill({
    super.key,
    required this.scene,
    required this.progress,
    this.animate = true,
  });

  final FocusScene scene;
  final double progress; // 0 비었음 → 1 가득
  final bool animate;

  @override
  State<SceneFill> createState() => _SceneFillState();
}

class _SceneFillState extends State<SceneFill> with WidgetsBindingObserver {
  final _time = ValueNotifier<double>(0);
  final _watch = clock.stopwatch();
  Timer? _timer;
  bool _visible = true;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _sync();
  }

  @override
  void didUpdateWidget(SceneFill old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final run = widget.animate && _visible && !_reduce;
    if (run && _timer == null) {
      _watch.start();
      _timer = Timer.periodic(FillMotion.frame, (_) {
        _time.value = _watch.elapsedMilliseconds / 1000;
      });
    } else if (!run && _timer != null) {
      _timer!.cancel();
      _timer = null;
      _watch.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: SceneFillPainter(
                scene: widget.scene, progress: widget.progress, time: _time),
          ),
        ),
      );
}

class SceneFillPainter extends CustomPainter {
  SceneFillPainter(
      {required this.scene, required this.progress, required this.time})
      : super(repaint: time);

  final FocusScene scene;
  final double progress;
  final ValueListenable<double> time;

  // 별 고정 좌표 (x 비율, y 비율)
  static final _stars = [
    for (var i = 0; i < 48; i++)
      ((i * 0.754877 + 0.11) % 1.0, (i * 0.569840 + 0.05) % 1.0)
  ];

  /// 0~1 고정 난수 (같은 나무는 항상 같은 값)
  static double _hash(int a, int b) {
    final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = scene.style;
    switch (scene) {
      case FocusScene.ocean:
        _ocean(canvas, size, t, s);
      case FocusScene.forest:
        _forest(canvas, size, t, s);
      case FocusScene.night:
        _night(canvas, size, t, s);
      case FocusScene.daily:
        _coffee(canvas, size, t, s);
    }
  }

  Path _wave(Size size, double y, double amp, double phase, double k) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, y + amp * math.sin(phase));
    const step = 8.0;
    for (var x = step; x < size.width + step; x += step) {
      path.lineTo(x, y + amp * math.sin(k * x + phase));
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  /// 바다·커피 공통 출렁임: 뒤 물결 + 앞 물결 + 앞 물결 머리의 밝은 선
  void _swell(Canvas c, Size size, double t, double y, Paint back, Paint front,
      Color crestColor) {
    final k = 2 * math.pi / size.width;
    final b = 2 * math.pi * t / FillMotion.waveBackPeriod;
    final f = 2 * math.pi * t / FillMotion.waveFrontPeriod;
    c.drawPath(_wave(size, y - 8, FillMotion.waveBackAmp, b, k * 1.2), back);
    c.drawPath(_wave(size, y + 6, FillMotion.waveFrontAmp, -f, k * 1.7), front);
    final crest = Path();
    for (var x = 0.0; x <= size.width + 8; x += 8) {
      final py = y + 6 + FillMotion.waveFrontAmp * math.sin(k * 1.7 * x - f);
      x == 0 ? crest.moveTo(x, py) : crest.lineTo(x, py);
    }
    c.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = crestColor);
  }

  void _ocean(Canvas c, Size size, double t, SceneStyle s) {
    final y = fillSurfaceY(size.height, progress,
        overshoot: FillMotion.waveOvershoot);
    _swell(c, size, t, y, Paint()..color = s.fill, Paint()..color = s.fillDeep,
        s.fillCrest);
  }

  /// 먼 줄부터 그려 가까운 나무가 덮는다. 나무는 아래 줄부터 차례로, 연한 색에서 진한 색으로 물들며 자란다.
  void _forest(Canvas c, Size size, double t, SceneStyle s) {
    final unit = size.width / 402;
    final sway = FillMotion.treeSwayDeg *
        math.pi /
        180 *
        math.sin(2 * math.pi * t / FillMotion.treeSwayPeriod);
    // 땅도 함께 차오르고 짙어진다
    final ground = fillSurfaceY(size.height, progress, overshoot: 8);
    c.drawPath(_wave(size, ground, 8, 0.6, 2 * math.pi / size.width),
        Paint()..color = Color.lerp(s.fill, s.fillShade, progress)!);
    const rows = FillMotion.forestRows;
    for (var r = rows - 1; r >= 0; r--) {
      final fy = r / (rows - 1); // 0 맨 아래 → 1 맨 위
      final h = (FillMotion.treeNear +
              (FillMotion.treeFar - FillMotion.treeNear) * fy) *
          unit;
      final cols = 4 + (fy * 2).round();
      for (var i = 0; i <= cols; i++) {
        final jitter = _hash(r, i);
        // 마지막 줄도 진행 1에서 다 자란다
        final start = fy * (0.96 - FillMotion.treeGrow) + jitter * 0.04;
        final grow = ((progress - start) / FillMotion.treeGrow).clamp(0.0, 1.0);
        if (grow <= 0) continue;
        final x = (i + (r.isOdd ? 0.5 : 0.0) + (jitter - 0.5) * 0.4) /
            cols *
            size.width;
        // 먼 줄은 밝게, 가까운 줄은 짙게. 처음엔 연한 색으로 시작한다.
        final target = Color.lerp(
            s.fillDeep, s.fillShade, (1 - fy) * 0.75 + jitter * 0.25)!;
        final root = Offset(
            x, size.height * (1 - fy) + h * 0.12 + (jitter - 0.5) * 16 * unit);
        _tree(c, root, h * (0.25 + 0.75 * grow), sway * (0.6 + jitter),
            Color.lerp(s.fill, target, grow)!, s, grow);
      }
    }
  }

  void _tree(Canvas c, Offset root, double h, double sway, Color leaf,
      SceneStyle s, double grow) {
    c.save();
    c.translate(root.dx, root.dy);
    c.rotate(sway);
    final paint = Paint()..color = leaf;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-h * 0.06, -h * 0.5, h * 0.12, h * 0.5),
            Radius.circular(h * 0.04)),
        Paint()..color = Color.lerp(s.fill, s.fillShade, grow)!);
    c.drawCircle(Offset(0, -h * 0.68), h * 0.32, paint);
    c.drawCircle(Offset(-h * 0.2, -h * 0.48), h * 0.24, paint);
    c.drawCircle(Offset(h * 0.2, -h * 0.48), h * 0.24, paint);
    c.restore();
  }

  /// 경계선 없이 화면 전체가 보라빛 해질녘에서 우주 검정으로. 어두워질수록 별이 늘어난다.
  void _night(Canvas c, Size size, double t, SceneStyle s) {
    final fade = (progress / FillMotion.nightFadeIn).clamp(0.0, 1.0);
    final dark =
        ((progress - FillMotion.nightFadeIn) / (1 - FillMotion.nightFadeIn))
            .clamp(0.0, 1.0);
    Color at(Color start) =>
        Color.lerp(Color.lerp(s.cardBg, start, fade), s.fillDeep, dark)!;
    final rect = Offset.zero & size;
    c.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [at(s.fill), at(s.fillGlow ?? s.fill)],
          ).createShader(rect));
    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final show = ((progress - i / _stars.length * 0.9) / 0.1).clamp(0.0, 1.0);
      if (show <= 0) continue;
      final (fx, fy) = _stars[i];
      final twinkle =
          0.8 + 0.2 * math.sin(2 * math.pi * t / FillMotion.starPeriod + i);
      c.drawCircle(
          Offset(fx * size.width, fy * size.height),
          FillMotion.starRadius * (0.6 + 0.8 * _hash(i, 7)),
          star..color = s.fillCrest.withValues(alpha: show * twinkle));
    }
  }

  // 얼음 큐브 면 (꼭짓점 거리 1 기준). 빛은 왼쪽 위에서 온다.
  static Path _face(List<Offset> p) => Path()..addPolygon(p, true);
  static const _cubeW = 0.87;
  static final _iceTop = _face(const [
    Offset(0, -1),
    Offset(_cubeW, -0.5),
    Offset(0, 0),
    Offset(-_cubeW, -0.5),
  ]);
  static final _iceLeft = _face(const [
    Offset(-_cubeW, -0.5),
    Offset(0, 0),
    Offset(0, 1),
    Offset(-_cubeW, 0.5),
  ]);
  static final _iceRight = _face(const [
    Offset(_cubeW, -0.5),
    Offset(0, 0),
    Offset(0, 1),
    Offset(_cubeW, 0.5),
  ]);
  static final _iceOutline = _face(const [
    Offset(0, -1),
    Offset(_cubeW, -0.5),
    Offset(_cubeW, 0.5),
    Offset(0, 1),
    Offset(-_cubeW, 0.5),
    Offset(-_cubeW, -0.5),
  ]);
  static final _iceInner = Path()
    ..moveTo(-_cubeW, -0.5)
    ..lineTo(0, 0)
    ..lineTo(_cubeW, -0.5)
    ..moveTo(0, 0)
    ..lineTo(0, 1);
  static final _iceGlint = _face(const [
    Offset(-0.1, -0.72),
    Offset(0.28, -0.53),
    Offset(0.1, -0.43),
    Offset(-0.28, -0.62),
  ]);

  // 얼음 (x 비율, 수면 아래 깊이, 크기, 기울기). 수면과 함께 올라온다.
  static const _ice = [
    (0.12, 14.0, 58.0, 0.22),
    (0.36, 6.0, 46.0, -0.3),
    (0.58, 16.0, 62.0, 0.12),
    (0.86, 8.0, 50.0, -0.18),
    (0.24, 92.0, 44.0, 0.42),
    (0.74, 104.0, 52.0, -0.36),
    (0.08, 190.0, 40.0, -0.1),
    (0.92, 214.0, 42.0, 0.3),
  ];

  /// 잔 안을 들여다본 모습: 바다처럼 출렁이는 커피 + 떠 있는 얼음
  void _coffee(Canvas c, Size size, double t, SceneStyle s) {
    final y = fillSurfaceY(size.height, progress,
        overshoot: FillMotion.waveOvershoot);
    _swell(
        c,
        size,
        t,
        y,
        Paint()..color = Color.lerp(s.fill, s.fillCrest, 0.28)!,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [s.fill, s.fillDeep],
          ).createShader(Rect.fromLTRB(0, y, size.width, size.height + 1)),
        Color.lerp(s.fill, s.fillCrest, 0.6)!);
    final bob = 2 * math.pi * t / FillMotion.iceBobPeriod;
    final shadow = Paint()..color = s.fillDeep.withValues(alpha: 0.45);
    final top = Paint()..color = s.fillCrest.withValues(alpha: 0.88);
    final left = Paint()..color = s.fillCrest.withValues(alpha: 0.5);
    final right = Paint()..color = s.fillCrest.withValues(alpha: 0.26);
    final glint = Paint()..color = s.fillCrest;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = s.fillCrest.withValues(alpha: 0.9);
    for (var i = 0; i < _ice.length; i++) {
      final (fx, depth, side, tilt) = _ice[i];
      final cy = y + depth + FillMotion.iceBob * math.sin(bob + i);
      if (cy - side > size.height) continue;
      c.save();
      c.translate(fx * size.width, cy);
      c.rotate(tilt + 0.03 * math.sin(bob + i * 2));
      final a = side * 0.58;
      c.scale(a);
      c.save();
      c.translate(0.14, 0.2);
      c.drawPath(_iceOutline, shadow);
      c.restore();
      c.drawPath(_iceTop, top);
      c.drawPath(_iceLeft, left);
      c.drawPath(_iceRight, right);
      c.drawPath(_iceOutline, edge..strokeWidth = 2 / a);
      c.drawPath(_iceInner, edge..strokeWidth = 1.5 / a);
      c.drawPath(_iceGlint, glint);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(SceneFillPainter o) =>
      o.scene != scene || o.progress != progress;
}
