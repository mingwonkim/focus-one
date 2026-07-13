// lib/features/mini/widgets/focus_ring.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_tokens.dart';
import '../../../core/scene_decorations.dart';

/// 시안의 타이머 다이얼: 장면 풍경이 채워진 원 + 진행 링 + 중앙 시간.
/// 미니(88, stroke 5, inset 9) / 확장(216, stroke 8, inset 15) 두 규격.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.progress, // 1.0(시작) → 0.0(종료)
    required this.remainingSeconds,
    required this.scene,
    this.size = 88,
    this.stroke = 5,
    this.inset = 9,
    this.stateLabel,
    this.showLabel = true,
  });

  final double progress;
  final int remainingSeconds;
  final FocusScene scene;
  final double size;
  final double stroke;
  final double inset;
  final String? stateLabel; // 확장 다이얼에만 표시 ('집중하는 중' 등)
  final bool showLabel; // 소형(48px 이하)에서는 시간을 밖에 표시

  String get _label {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final style = scene.style;
    final big = stateLabel != null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 다이얼 안 풍경
          Positioned.fill(
            left: inset,
            top: inset,
            right: inset,
            bottom: inset,
            child: CustomPaint(painter: SceneDialPainter(scene)),
          ),
          // 진행 링
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                stroke: stroke,
                accent: style.accent,
                track: style.ringTrack,
                glow: big,
              ),
            ),
          ),
          // 중앙 시간 (+ 상태 라벨)
          if (showLabel)
            Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label,
                style: TextStyle(
                  fontSize: big ? 44 : 17,
                  fontWeight: FontWeight.w900,
                  color: style.timeColor,
                  letterSpacing: big ? 0.88 : 0.34,
                  height: 1.1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: [
                    Shadow(
                      color: style.timeShadow,
                      blurRadius: big ? 14 : 8,
                      offset: Offset(0, big ? 2 : 1),
                    ),
                  ],
                ),
              ),
              if (big) ...[
                const SizedBox(height: 2),
                Text(
                  stateLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.16, // 0.18em
                    color: style.timeColor.withValues(alpha: 0.95),
                    shadows: [
                      Shadow(
                        color: style.timeShadow,
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.accent,
    required this.track,
    required this.glow,
  });

  final double progress;
  final double stroke;
  final Color accent;
  final Color track;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // 시안: 88px 다이얼에 r40 (stroke 5), 216px에 r98 (stroke 8)
    final radius = size.width / 2 - stroke / 2 - 1.5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    final sweep = 2 * math.pi * progress;
    if (sweep <= 0) return;

    if (glow) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = accent.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawArc(
      rect,
      -math.pi / 2, // 12시 방향 시작
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.track != track ||
      old.stroke != stroke ||
      old.glow != glow;
}
