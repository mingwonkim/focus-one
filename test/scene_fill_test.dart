// 차오름 높이: 시작은 화면 아래, 끝은 화면 위까지 빈틈 없이
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/mobile/focus/scene_fill.dart';

void main() {
  test('수면 위치', () {
    const h = 800.0;
    expect(fillSurfaceY(h, 0, margin: 20), 820);
    expect(fillSurfaceY(h, 1, margin: 20), -20);
    expect(fillSurfaceY(h, 0.5), 400);
    expect(fillSurfaceY(h, 2), 0); // 범위 밖은 자른다
  });

  for (final scene in FocusScene.values) {
    testWidgets('${scene.name} 진행도별 그리기 예외 없음', (tester) async {
      for (final p in [0.0, 0.25, 0.5, 0.75, 1.0]) {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: SceneFill(scene: scene, progress: p),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('동작 줄이기면 움직임 타이머를 돌리지 않는다', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SceneFill(scene: FocusScene.ocean, progress: 0.5),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
