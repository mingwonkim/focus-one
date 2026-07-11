// lib/features/mini/widgets/focus_ring.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Time Timer 방식의 시각 타이머.
/// 숫자가 아니라 "채워진 면적이 줄어드는 것"으로 남은 시간을 보여준다.
/// ADHD의 time blindness 보조가 목적이므로 면적 표현이 핵심이다.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress, // 1.0(시작) → 0.0(종료)
    required this.remainingSeconds,
    this.size = 88,
    this.showLabel = true,
  });

  final double progress;
  final int remainingSeconds;
  final double size;
  final bool showLabel;

  String get _label {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _FocusRingPainter(
              progress: progress.clamp(0.0, 1.0),
              fillColor: scheme.primary,
              trackColor: scheme.outline.withValues(alpha: 0.4),
            ),
          ),
          if (showLabel)
            Text(
              _label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
        ],
      ),
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  final double progress;
  final Color fillColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // 바깥 트랙 (전체 원 테두리)
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = trackColor;
    canvas.drawCircle(center, radius - 1.5, trackPaint);

    // 남은 시간만큼 채워진 파이 (12시 방향 기준, 시계방향으로 줄어듦)
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor.withValues(alpha: 0.85);
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2, // 12시 방향 시작
      sweep,
      true,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor;
}
