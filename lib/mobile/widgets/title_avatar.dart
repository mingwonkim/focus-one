// lib/mobile/widgets/title_avatar.dart
// 칭호 테두리 아바타: 가운데 친구 그림 + 칭호별 링(색·빛·회전·별). 프로필·랭킹·승급·공유 카드 공통.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/focus_title.dart';

class TitleAvatar extends StatefulWidget {
  const TitleAvatar({
    super.key,
    required this.title,
    required this.asset,
    required this.background,
    this.size = MobileSize.avatar,
  });

  final FocusTitle title;
  final String asset; // 친구 그림 경로 ('' 이면 사람 아이콘)
  final Color background;
  final double size;

  @override
  State<TitleAvatar> createState() => _TitleAvatarState();
}

class _TitleAvatarState extends State<TitleAvatar>
    with SingleTickerProviderStateMixin {
  late final _spin =
      AnimationController(vsync: this, duration: AppDuration.titleSpin);

  TitleRing get _ring => TitleRings.all[widget.title.index];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TitleAvatar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_ring.spin && !reduce) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = _ring;
    final size = widget.size;
    // 링 두께는 기본 크기(56) 기준 → 큰 아바타에선 비례해 굵게
    final scale = size / MobileSize.avatar;
    final inset = (ring.width + 2) * scale;
    return Semantics(
      label: '칭호 ${widget.title.label}',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(ring, _spin, scale),
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: ClipOval(
              child: ColoredBox(
                color: widget.background,
                child: widget.asset.isEmpty
                    ? Icon(Icons.person_rounded,
                        size: size * 0.5, color: ring.colors.first)
                    : Padding(
                        padding: EdgeInsets.all(size * 0.08),
                        child: Image.asset(widget.asset, fit: BoxFit.contain),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.ring, this.spin, this.scale) : super(repaint: spin);

  final TitleRing ring;
  final Animation<double> spin;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = ring.width * scale;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - w / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    final angle = spin.value * 2 * math.pi;
    final colors = ring.colors.length == 1
        ? ring.colors
        : [...ring.colors, ring.colors.first]; // 이음새 없이 한 바퀴
    Paint stroke(double width) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width;
      if (colors.length == 1) {
        p.color = colors.first;
      } else {
        p.shader = SweepGradient(
          colors: colors,
          transform: GradientRotation(angle),
        ).createShader(rect);
      }
      return p;
    }

    if (ring.glow > 0) {
      canvas.drawCircle(
          c,
          r,
          stroke(w * 1.6)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring.glow * scale));
    }
    canvas.drawCircle(c, r, stroke(w));
    if (ring.stars) {
      final star = Paint()..color = TitleRings.star;
      for (var i = 0; i < 3; i++) {
        final a = angle + i * 2 * math.pi / 3 - math.pi / 2;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r,
            w * 0.45, star);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ring != ring || old.scale != scale;
}
