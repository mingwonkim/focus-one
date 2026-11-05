// lib/mobile/focus/scene_fill.dart
// 집중 중 화면 전체 차오름: 바다 파도 · 숲 풀과 나무 · 밤 달빛과 별 · 일상 커피.
// 높이는 남은 시간(시계)에서만 나온다. 움직임은 약 24fps로 제한하고 앱이 안 보이면 멈춘다.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';

/// 수면 y. p=0이면 화면 아래로, p=1이면 화면 위로 [margin]만큼 넘겨 물결이 비지 않게 한다.
double fillSurfaceY(double height, double p, {double margin = 0}) {
  final t = p.clamp(0.0, 1.0);
  return (height + margin) - t * (height + margin * 2);
}

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
  final _watch = Stopwatch();
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

  // 고정 좌표 (x 비율, 아래에서부터 높이 비율)
  static const _trees = [
    // 가운데는 링 자리라 양옆에만
    (0.11, 0.14, 1.0),
    (0.90, 0.27, 0.85),
    (0.08, 0.46, 0.8),
    (0.92, 0.60, 0.9),
    (0.12, 0.74, 0.75),
  ];
  static final _grass = [
    for (var i = 0; i < 16; i++)
      ((i * 0.381966 + 0.07) % 1.0, (i * 0.618034 + 0.03) % 1.0)
  ];
  static final _stars = [
    for (var i = 0; i < 24; i++)
      ((i * 0.754877 + 0.11) % 1.0, (i * 0.569840 + 0.05) % 1.0)
  ];

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

  void _ocean(Canvas c, Size size, double t, SceneStyle s) {
    const m = FillMotion.waveBackAmp * 2;
    final y = fillSurfaceY(size.height, progress, margin: m);
    final k = 2 * math.pi / size.width;
    final back = 2 * math.pi * t / FillMotion.waveBackPeriod;
    final front = 2 * math.pi * t / FillMotion.waveFrontPeriod;
    c.drawPath(_wave(size, y - 8, FillMotion.waveBackAmp, back, k * 1.2),
        Paint()..color = s.fill);
    final path = _wave(size, y + 6, FillMotion.waveFrontAmp, -front, k * 1.7);
    c.drawPath(path, Paint()..color = s.fillDeep);
    // 앞 물결 머리의 밝은 선
    final crest = Path();
    for (var x = 0.0; x <= size.width + 8; x += 8) {
      final py = y + 6 + FillMotion.waveFrontAmp * math.sin(k * 1.7 * x - front);
      x == 0 ? crest.moveTo(x, py) : crest.lineTo(x, py);
    }
    c.drawPath(
        crest,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = s.fillCrest);
  }

  void _forest(Canvas c, Size size, double t, SceneStyle s) {
    const m = FillMotion.grassHeight;
    final y = fillSurfaceY(size.height, progress, margin: m);
    final sway = FillMotion.treeSwayDeg *
        math.pi /
        180 *
        math.sin(2 * math.pi * t / FillMotion.treeSwayPeriod);
    // 땅: 위가 살짝 둥근 언덕
    final k = 2 * math.pi / size.width;
    c.drawPath(_wave(size, y, 8, 0.6, k * 0.8), Paint()..color = s.fill);
    final blade = Paint()
      ..color = s.fillDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final (fx, fy) in _grass) {
      final rootY = size.height * (1 - fy * progress);
      if (rootY > size.height) continue;
      _tuft(c, Offset(fx * size.width, rootY),
          FillMotion.grassHeight * ((progress - fy * progress + 0.2).clamp(0.0, 1.0) * 0.5 + 0.5), sway, blade);
    }
    for (final (fx, fy, scale) in _trees) {
      // 땅이 뿌리 높이를 지나면 그때부터 자란다
      final grow = ((progress - fy) / 0.22).clamp(0.0, 1.0);
      if (grow <= 0) continue;
      _tree(c, Offset(fx * size.width, size.height * (1 - fy)),
          FillMotion.treeHeight * scale * grow, sway, s);
    }
  }

  void _tuft(Canvas c, Offset root, double h, double sway, Paint p) {
    for (final a in [-0.32, 0.0, 0.32]) {
      final tip = root +
          Offset(math.sin(a + sway * 4) * h, -math.cos(a + sway * 4) * h);
      c.drawLine(root, tip, p);
    }
  }

  void _tree(Canvas c, Offset root, double h, double sway, SceneStyle s) {
    c.save();
    c.translate(root.dx, root.dy);
    c.rotate(sway);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-h * 0.07, -h * 0.5, h * 0.14, h * 0.5),
            Radius.circular(h * 0.05)),
        Paint()..color = s.mobileBottom);
    c.drawCircle(Offset(0, -h * 0.66), h * 0.34, Paint()..color = s.fillDeep);
    c.drawCircle(Offset(-h * 0.18, -h * 0.5), h * 0.22, Paint()..color = s.fillDeep);
    c.drawCircle(Offset(h * 0.18, -h * 0.5), h * 0.22, Paint()..color = s.fillDeep);
    c.drawCircle(Offset(-h * 0.1, -h * 0.76), h * 0.1, Paint()..color = s.fillCrest);
    c.restore();
  }

  void _night(Canvas c, Size size, double t, SceneStyle s) {
    const m = FillMotion.waveBackAmp;
    final y = fillSurfaceY(size.height, progress, margin: m);
    final k = 2 * math.pi / size.width;
    c.drawPath(_wave(size, y, m, 2 * math.pi * t / FillMotion.waveBackPeriod, k),
        Paint()..color = s.fill);
    final star = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final (fx, fy) = _stars[i];
      final sy = fy * size.height;
      if (sy < y) continue; // 달빛이 지난 자리만
      final a = 0.85 +
          0.15 * math.sin(2 * math.pi * t / FillMotion.starPeriod + i);
      c.drawCircle(Offset(fx * size.width, sy), FillMotion.starRadius,
          star..color = s.fillCrest.withValues(alpha: a));
    }
    // 끝 무렵 위쪽에 달이 드러난다
    final moon = Offset(size.width * 0.78, size.height * 0.1);
    if (moon.dy > y) {
      c.drawCircle(moon, FillMotion.moonRadius, Paint()..color = s.fillCrest);
      c.drawCircle(moon + const Offset(-12, -6), FillMotion.moonRadius * 0.82,
          Paint()..color = s.fill);
    }
  }

  void _coffee(Canvas c, Size size, double t, SceneStyle s) {
    const m = FillMotion.cremaAmp * 4;
    final y = fillSurfaceY(size.height, progress, margin: m);
    final k = 2 * math.pi / size.width;
    final phase = 2 * math.pi * t / FillMotion.cremaPeriod;
    // 위쪽 크레마 띠 → 아래 커피
    c.drawPath(_wave(size, y, FillMotion.cremaAmp, phase, k),
        Paint()..color = s.fillCrest);
    c.drawPath(_wave(size, y + 14, FillMotion.cremaAmp, phase, k),
        Paint()..color = s.fill);
    c.drawPath(_wave(size, y + 14 + size.height * 0.25, FillMotion.cremaAmp, phase, k),
        Paint()..color = s.fillDeep);
  }

  @override
  bool shouldRepaint(SceneFillPainter o) =>
      o.scene != scene || o.progress != progress;
}
