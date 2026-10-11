// P3: 태그·친구·보상·배치·통계
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/models/task.dart';
import 'package:focus_one/state/app_state.dart';
import 'package:focus_one/state/stats.dart';

FocusSession s(DateTime end, int sec,
        {String? tag, SessionOutcome o = SessionOutcome.completed, bool legacy = false}) =>
    FocusSession(
      id: '${end.microsecondsSinceEpoch}',
      taskId: '',
      taskTitle: '',
      minutes: sec ~/ 60,
      endedAt: end,
      focusedSec: legacy ? null : sec,
      segments: legacy ? const [] : [(end.subtract(Duration(seconds: sec)), end)],
      tagId: tag,
      outcome: o,
      scene: 'forest',
    );

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('focusone'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppState> boot(DateTime at) => withClock(Clock.fixed(at), () async {
        final st = AppState(LocalStore(File('${dir.path}/d.json')));
        await st.init();
        return st;
      });

  test('소리: 장면 기본·상황 소리, 장면 바꾸면 다른 장면 상황 소리는 기본으로', () async {
    final st = await boot(DateTime(2026, 10, 11, 9));
    st.setScene(FocusScene.forest);
    expect(st.soundAsset, 'sounds/forest.m4a');
    st.setSoundId('birds');
    expect(st.soundAsset, 'sounds/birds.m4a');
    st.setScene(FocusScene.daily);
    expect(st.soundAsset, 'sounds/cafe.m4a');
    st.setSoundId('rain');
    st.setScene(FocusScene.ocean);
    expect(st.soundAsset, 'sounds/rain.m4a');
    for (final sc in FocusScene.values) {
      for (final id in [
        sc.phoneSound,
        ...sc.situationSounds,
        'rain',
        'wind',
        'white',
        'brown'
      ]) {
        expect(File('assets/sounds/$id.m4a').existsSync(), isTrue, reason: id);
      }
    }
    st.dispose();
  });

  test('완료 시 친구 1 + 물방울(분) — 재실행해도 한 번만', () async {
    final t0 = DateTime(2026, 10, 11, 9);
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    expect(a.activeSession!.companionId, 'fawn');
    expect(a.activeSession!.tagId, 'general');
    await a.flush();
    a.dispose();

    final b = await boot(t0.add(const Duration(hours: 1)));
    expect(b.ownedCount('fawn'), 1);
    expect(b.drops, 25);
    expect(b.sessions.single.companionId, 'fawn');
    await b.flush();
    b.dispose();
    final c = await boot(t0.add(const Duration(hours: 2)));
    expect(c.ownedCount('fawn'), 1);
    expect(c.drops, 25);
    expect(c.buyDecor('grass'), isTrue);
    expect(c.rankScore, 25); // 상점에서 써도 랭킹 점수는 그대로
    c.dispose();
  });

  test('그만두기는 보상 없음', () async {
    final t0 = DateTime(2026, 10, 11, 9);
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    withClock(Clock.fixed(t0.add(const Duration(minutes: 20))), a.abandonSession);
    expect(a.ownedCount('fawn'), 0);
    expect(a.drops, 0);
    a.dispose();
  });

  test('비상 탈출: 남은 1분당 물방울 2, 모자라면 못 끝냄', () async {
    final t0 = DateTime(2026, 10, 11, 9);
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    await a.flush();
    a.dispose();
    final b = await boot(t0.add(const Duration(hours: 1))); // 25분 완료 → 25개
    final t1 = t0.add(const Duration(hours: 1));
    withClock(Clock.fixed(t1), () => b.startTimer(allowNoTask: true));
    withClock(Clock.fixed(t1.add(const Duration(minutes: 5))), () {
      expect(b.escapeCost, 40); // 20분 남음
      expect(b.escapeSession(), isFalse);
    });
    withClock(Clock.fixed(t1.add(const Duration(minutes: 15, seconds: 30))), () {
      expect(b.escapeCost, 20); // 9분 30초 남음 → 10분
      expect(b.escapeSession(), isTrue);
    });
    expect(b.activeSession, isNull);
    expect(b.drops, 5);
    expect(b.ownedCount('fawn'), 1);
    expect(b.rankScore, 5); // 모은 25 − 탈출 20
    b.dispose();
  });

  test('친구 해금은 장면 누적 완료 분, 잠긴 친구는 선택 불가', () async {
    final a = await boot(DateTime(2026, 10, 11));
    final squirrel = Companion.byId('squirrel')!;
    expect(a.isUnlocked(squirrel), isFalse);
    a.selectCompanion('squirrel');
    expect(a.selectedCompanion.id, 'fawn');
    a.dispose();
  });

  test('배치: 빈 칸·보유 수 안에서만, 회수 가능', () async {
    final a = await boot(DateTime(2026, 10, 11));
    expect(a.place(FocusScene.forest, 'fawn', 0, 0), isFalse); // 보유 0
    expect(a.buyDecor('tree'), isFalse); // 물방울 부족
    a.dispose();
  });

  test('편집 완료: 겹침·보유 초과면 거절하고 아무것도 안 바꿈', () async {
    final t0 = DateTime(2026, 10, 11, 9);
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    await a.flush();
    a.dispose();
    final b = await boot(t0.add(const Duration(hours: 1))); // 새싹사슴 1마리 획득
    expect(b.setPlacements(FocusScene.forest, const [Placement('fawn', 0, 0), Placement('fawn', 1, 0)]), isFalse);
    expect(b.setPlacements(FocusScene.forest, const [Placement('fawn', 0, 0)]), isTrue);
    expect(b.setPlacements(FocusScene.night, const [Placement('fawn', 2, 2)]), isFalse); // 숲에 이미 놓음
    expect(b.placementsOf(FocusScene.forest).single.x, 0);
    expect(b.placementsOf(FocusScene.night), isEmpty);
    b.dispose();
  });

  test('태그 삭제해도 기록은 남고 마지막 태그는 못 지움', () async {
    final a = await boot(DateTime(2026, 10, 11));
    a.addTag('운동');
    final gym = a.tags.last.id;
    a.addTask('스쿼트');
    a.setTaskTag(a.pendingTasks.single.id, gym);
    a.deleteTag(gym);
    expect(a.tags.map((t) => t.name), ['미분류']);
    expect(a.pendingTasks.single.tagId, isNull);
    a.deleteTag('general');
    expect(a.tags, isNotEmpty);
    a.dispose();
  });

  test('태그 삭제 후에도 그 태그 기록은 남고 재실행해도 유지', () async {
    final t0 = DateTime(2026, 10, 11, 9);
    final a = await boot(t0);
    a.addTag('운동');
    final gym = a.tags.last.id;
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    // 완료는 재실행 때 시각으로 확정된다
    await a.flush();
    a.dispose();
    final b = await boot(t0.add(const Duration(hours: 1)));
    expect(b.sessions.single.tagId, gym);
    b.deleteTag(gym);
    await b.flush();
    b.dispose();
    final c = await boot(t0.add(const Duration(hours: 2)));
    expect(c.tags.any((t) => t.id == gym), isFalse);
    expect(c.sessions.single.tagId, gym);
    expect(FocusStats(c.sessions).byTag(DateTime(2026, 10, 11), DateTime(2026, 10, 12)),
        {gym: 25 * 60});
    c.dispose();
  });

  test('일시정지로 나뉜 구간은 실제 시각대로 집계, 완료 시각은 예정 종료', () async {
    final t0 = DateTime(2026, 10, 10, 23, 50);
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () => a.startTimer(allowNoTask: true));
    withClock(Clock.fixed(DateTime(2026, 10, 11, 0, 0)), a.pauseTimer);
    withClock(Clock.fixed(DateTime(2026, 10, 11, 1, 0)), () => a.startTimer(allowNoTask: true));
    await a.flush();
    a.dispose();
    // 다음 날 아침에 열어도 기록은 01:15 완료
    final b = await boot(DateTime(2026, 10, 11, 9));
    final x = b.sessions.single;
    expect(x.endedAt, DateTime(2026, 10, 11, 1, 15));
    final st = FocusStats(b.sessions);
    expect(st.daily()[DateTime(2026, 10, 10)], 10 * 60);
    expect(st.daily()[DateTime(2026, 10, 11)], 15 * 60);
    expect(st.hours(DateTime(2026, 10, 11))[1], 15 * 60);
    expect(st.hours(DateTime(2026, 10, 11))[0], 0); // 일시정지 시간은 집중 아님
    b.dispose();
  });

  group('FocusStats', () {
    test('자정 걸친 세션은 두 날로 나뉨', () {
      final st = FocusStats([s(DateTime(2026, 10, 11, 0, 20), 40 * 60)]);
      final d = st.daily();
      expect(d[DateTime(2026, 10, 10)], 20 * 60);
      expect(d[DateTime(2026, 10, 11)], 20 * 60);
    });

    test('구기록은 끝난 날에 통째로, 골든타임에서는 제외', () {
      final st = FocusStats([s(DateTime(2026, 10, 11, 9), 25 * 60, legacy: true)]);
      expect(st.daily()[DateTime(2026, 10, 11)], 25 * 60);
      expect(st.goldenHours(DateTime(2026, 10, 11, 23)), isEmpty);
    });

    test('연속일은 1분 이상인 날, 오늘 없으면 어제부터', () {
      final st = FocusStats([
        s(DateTime(2026, 10, 9, 10), 600),
        s(DateTime(2026, 10, 10, 10), 600),
        s(DateTime(2026, 10, 8, 10), 30), // 1분 미만 → 끊김
      ]);
      expect(st.streak(DateTime(2026, 10, 11, 8)), 2);
    });

    test('태그 분포·완료 횟수·골든타임', () {
      final st = FocusStats([
        s(DateTime(2026, 10, 11, 10), 3600, tag: 'a'),
        s(DateTime(2026, 10, 11, 15), 600, tag: 'b', o: SessionOutcome.abandoned),
      ]);
      final from = DateTime(2026, 10, 11), to = DateTime(2026, 10, 12);
      expect(st.byTag(from, to), {'a': 3600, 'b': 600});
      expect(st.completedCount(from, to), 1);
      expect(st.goldenHours(DateTime(2026, 10, 11, 23)), [9]);
      expect(st.monthDots(DateTime(2026, 10))[DateTime(2026, 10, 11)], (3, 'forest'));
      expect(st.monthDots(DateTime(2026, 10)).length, 31);
    });
  });
}
