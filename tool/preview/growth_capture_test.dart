// v3 2단계 미리보기: 홈 스탯·목표·연속일·보상 시트 (macOS 전용). CI 대상 아님.
// 실행: flutter test tool/preview/growth_capture_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:focus_one/core/app_theme.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/mobile/growth/growth_pages.dart';
import 'package:focus_one/mobile/mobile_shell.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/models/growth.dart';
import 'package:focus_one/models/task.dart';
import 'package:focus_one/state/app_state.dart';

import 'capture_test.dart' show loadFont;

const out = String.fromEnvironment('OUT', defaultValue: '/tmp');

void main() {
  testWidgets('growth capture', (tester) async {
    await tester.runAsync(loadFont);
    await tester.runAsync(() async {
      final bytes = File('assets/fonts/Jua-Regular.ttf').readAsBytesSync();
      await (FontLoader('Jua')
            ..addFont(Future.value(ByteData.view(bytes.buffer))))
          .load();
    });
    final dir = Directory.systemTemp.createTempSync('fo');
    addTearDown(() => dir.deleteSync(recursive: true));
    final now = DateTime.now();
    DateTime ago(int d) => DateTime(now.year, now.month, now.day - d, 9);
    final file = File('${dir.path}/d.json');
    final skipped = dayKey(ago(4));
    await tester.runAsync(() => LocalStore(file).save(StoreData(
          tasks: const [],
          inbox: const [],
          sessions: [
            for (final d in [1, 2, 3, 5, 6, 7, 8, 9, 10])
              FocusSession(
                  id: 's$d',
                  taskId: '',
                  taskTitle: '',
                  minutes: 25,
                  endedAt: ago(d),
                  focusedSec: 1500,
                  scene: 'forest',
                  outcome: SessionOutcome.completed),
          ],
          progress: Progress(
            drops: 340,
            growth: Growth(
              migratedOn: dayKey(ago(30)),
              evaluatedThrough: dayKey(ago(1)),
              ice: 1,
              iceDays: {skipped},
            ),
          ),
        )));
    final state = AppState(LocalStore(file));
    await tester.runAsync(state.init);
    state.autoBreak = false;

    Future<void> shot(Widget home, String name, {bool wait = false}) async {
      final key = GlobalKey();
      const size = Size(402, 874);
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.of(state.scene).copyWith(
              textTheme: AppTheme.of(state.scene)
                  .textTheme
                  .apply(fontFamily: 'Jua')),
          home: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: const MediaQueryData(
                  size: size, padding: EdgeInsets.only(top: 59, bottom: 34)),
              child: DefaultTextStyle.merge(
                  style: const TextStyle(fontFamily: 'Jua'),
                  child: home),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1.5);
        final d = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/$name.png').writeAsBytesSync(d!.buffer.asUint8List());
      });
    }

    for (final scene in [FocusScene.forest, FocusScene.night]) {
      state.setScene(scene);
      await shot(const MobileShell(), '${scene.name}-home');
      await shot(const GoalPage(), '${scene.name}-goal');
      await shot(const StreakPage(), '${scene.name}-streak');
    }
    state.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
