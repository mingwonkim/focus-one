// 스토어 스크린샷용 예시 데이터 (macOS 로컬 전용, CI 대상 아님).
// 실행: flutter test tool/media/seed_test.dart --dart-define=OUT=<파일 경로>
// 결과 JSON을 시뮬레이터 앱의 Library/Application Support/focus_one_data.json 으로 복사.
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/state/app_state.dart';

const out = String.fromEnvironment('OUT', defaultValue: '/tmp/fokko_seed.json');

void main() {
  test('seed', () async {
    final f = File(out);
    for (final x in [f, File('$out.tmp'), File('$out.bak')]) {
      if (x.existsSync()) x.deleteSync(); // .bak이 남아 있으면 LocalStore가 복구해 데이터가 쌓임
    }
    Future<AppState> boot(DateTime at) => withClock(Clock.fixed(at), () async {
          final s = AppState(LocalStore(f));
          await s.init();
          return s;
        });

    final now = DateTime.now();
    final day0 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14)); // 어제까지
    var s = await boot(day0);
    // ID가 마이크로초 시각이라 Windows(시계 해상도가 거침)에선 연달아 만들면 겹친다 → 한 번에 하나씩 쉬며
    Future<void> each<T>(List<T> xs, void Function(T) f) async {
      for (final x in xs) {
        f(x);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    await each(['공부', '업무', '독서'], s.addTag);
    String tag(String n) => s.tags.firstWhere((t) => t.name == n).id;
    await each([
      ('토익 단어 50개 외우기', '공부'),
      ('기획서 초안 쓰기', '업무'),
      ('책 30쪽 읽기', '독서'),
      ('영어 쉐도잉 20분', '공부'),
      ('메일 답장하기', '업무'),
    ], (x) => s.addTask(x.$1, tagId: tag(x.$2)));
    await each(['세탁기 돌리기', '엄마한테 전화'], s.addToInbox);
    await s.flush();
    s.dispose();

    // (며칠 전, 시, 분, 길이, 장면, 태그)
    final plan = [
      for (var d = 0; d < 14; d++) ...[
        (d, 9, 30, d.isEven ? 50 : 25, FocusScene.values[d % 4], '공부'),
        if (d % 3 != 1) (d, 14, 0, 45, FocusScene.values[(d + 1) % 4], '업무'),
        if (d % 2 == 0) (d, 21, 10, 30, FocusScene.values[(d + 2) % 4], '독서'),
      ],
    ];
    for (final (d, h, m, mins, scene, tg) in plan) {
      final at = day0.add(Duration(days: d, hours: h, minutes: m));
      s = await boot(at);
      withClock(Clock.fixed(at), () {
        s.setScene(scene);
        final task = s.pendingTasks.firstWhere((t) => t.tagId == tag(tg));
        s.selectTask(task.id);
        s.selectTag(tag(tg)); // 이미 고른 할 일이면 selectTask가 태그를 안 바꾼다
        final locked = Companion.of(scene).where((c) => s.isUnlocked(c)).toList();
        s.selectCompanion(locked.last.id);
        s.setDurationMinutes(mins);
        s.startTimer();
      });
      await s.flush();
      s.dispose();
      s = await boot(at.add(Duration(minutes: mins + 1)));
      s.clearLastReward();
      await s.flush();
      s.dispose();
    }

    s = await boot(now);
    for (final d in ['grass', 'tree', 'bench', 'mug', 'books']) {
      s.buyDecor(d);
    }
    s.setPlacements(FocusScene.forest, const [
      Placement('tree', 0, 0),
      Placement('fawn', 2, 2),
      Placement('squirrel', 4, 1),
      Placement('grass', 1, 4),
      Placement('bench', 3, 4),
      Placement('fox', 5, 3),
    ]);
    s.setScene(FocusScene.forest);
    s.selectTask(s.pendingTasks.firstWhere((t) => t.title.startsWith('기획서')).id);
    s.setDurationMinutes(50);
    await s.flush();
    // ignore: avoid_print
    print('sessions=${s.sessions.length} drops=${s.drops} owned=${s.ownedCount('fawn')}');
    s.dispose();
  });
}
