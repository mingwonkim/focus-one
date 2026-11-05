// v3 2단계: 목표·연속일·얼음·이행. 재실행해도 결과가 같아야 한다.
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/models/growth.dart';
import 'package:focus_one/models/task.dart';
import 'package:focus_one/state/app_state.dart';

FocusSession session(DateTime end, int minutes,
        {SessionOutcome o = SessionOutcome.completed}) =>
    FocusSession(
      id: '${end.microsecondsSinceEpoch}',
      taskId: '',
      taskTitle: '',
      minutes: minutes,
      endedAt: end,
      focusedSec: minutes * 60,
      outcome: o,
      scene: 'forest',
    );

// 2026-11-09 는 월요일
final monday = DateTime(2026, 11, 9, 12);
DateTime day(int offset, [int hour = 12]) =>
    DateTime(2026, 11, 9 + offset, hour);

void main() {
  group('날짜', () {
    test('주는 월요일에 시작', () {
      expect(weekKey('2026-11-09'), '2026-11-09');
      expect(weekKey('2026-11-15'), '2026-11-09');
      expect(weekKey('2026-11-16'), '2026-11-16');
    });
    test('월 경계', () => expect(addDays('2026-10-31', 1), '2026-11-01'));
  });

  group('연속일·얼음', () {
    const g = Growth(evaluatedThrough: '2026-11-08', ice: 1);

    test('오늘 전이면 어제까지 유지, 오늘 하면 늘어남', () {
      final active = {'2026-11-08', '2026-11-07'};
      expect(g.streak('2026-11-09', active), 2);
      expect(g.streak('2026-11-09', {...active, '2026-11-09'}), 3);
    });

    test('빠진 날은 얼음이 메우고 연속수는 늘지 않는다', () {
      final active = {'2026-11-07', '2026-11-08', '2026-11-10'};
      final after = g.settled('2026-11-11', active);
      expect(after.ice, 0);
      expect(after.iceDays, {'2026-11-09'});
      expect(after.streak('2026-11-11', active), 3);
    });

    test('얼음이 모자라면 끊긴다', () {
      final active = {'2026-11-07', '2026-11-08'};
      final after = g.settled('2026-11-12', active);
      expect(after.ice, 0);
      expect(after.streak('2026-11-12', active), 0);
    });

    test('연속이 없으면 얼음을 쓰지 않는다', () {
      final after = g.settled('2026-11-12', {});
      expect(after.ice, 1);
      expect(after.iceDays, isEmpty);
    });

    test('다시 불러도 얼음을 두 번 쓰지 않는다', () {
      final active = {'2026-11-08'};
      final once = g.settled('2026-11-10', active);
      expect(once.settled('2026-11-10', active).ice, once.ice);
    });

    test('최고 기록은 끊겨도 남는다', () {
      final active = {'2026-11-01', '2026-11-02', '2026-11-03', '2026-11-08'};
      expect(g.bestStreak(active), 3);
    });
  });

  group('목표', () {
    test('올리면 바로, 낮추면 다음 기간부터, 원래 값이면 예약 취소', () {
      const p = GoalPlan(25);
      expect(p.changed(30, today: '2026-11-09', from: '2026-11-10').on('2026-11-09'), 30);
      final low = p.changed(10, today: '2026-11-09', from: '2026-11-10');
      expect(low.on('2026-11-09'), 25);
      expect(low.on('2026-11-10'), 10);
      expect(low.changed(25, today: '2026-11-09', from: '2026-11-10').nextMinutes, isNull);
    });
  });

  group('AppState', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('fo'));
    tearDown(() => dir.deleteSync(recursive: true));
    File file() => File('${dir.path}/d.json');
    StoreData store(List<FocusSession> sessions, [Progress? progress]) =>
        StoreData(
            tasks: const [],
            inbox: const [],
            sessions: sessions,
            progress: progress ?? const Progress());

    Future<AppState> boot(DateTime at) => withClock(Clock.fixed(at), () async {
          final st = AppState(LocalStore(file()));
          await st.init();
          await st.flush();
          return st;
        });

    /// 집중을 시작하고 앱을 끈 뒤, 끝날 시각에 다시 켠다 (세션 복구 경로로 완료된다)
    Future<AppState> focus(AppState st, DateTime at, int minutes) async {
      withClock(Clock.fixed(at), () {
        st.setDurationMinutes(minutes);
        st.startTimer(allowNoTask: true);
      });
      await st.flush();
      st.dispose();
      return boot(at.add(Duration(minutes: minutes)));
    }

    test('구버전 파일: 기록 보존, 얼음 1개, 다시 켜도 같음', () async {
      await LocalStore(file()).save(store([
        session(day(-2), 25),
        session(day(-1), 25, o: SessionOutcome.abandoned),
      ]));
      final raw = jsonDecode(file().readAsStringSync()) as Map<String, dynamic>;
      (raw['progress'] as Map<String, dynamic>).remove('growth');
      file().writeAsStringSync(jsonEncode(raw));

      final a = await boot(monday);
      expect(a.sessions, hasLength(2));
      expect(a.iceCount, 1);
      expect(withClock(Clock.fixed(monday), () => a.streakDays), 2,
          reason: '이행 전 중단 기록은 기존대로 인정');
      a.dispose();

      final b = await boot(monday);
      expect(b.iceCount, 1);
      expect(withClock(Clock.fixed(monday), () => b.streakDays), 2);
      b.dispose();
    });

    test('이행 뒤 중단은 연속일이 아니다', () async {
      (await boot(day(-1))).dispose();
      final d = await LocalStore(file()).load();
      await LocalStore(file()).save(
          store([session(day(0), 5, o: SessionOutcome.abandoned)], d.progress));
      final a = await boot(day(0, 13));
      expect(withClock(Clock.fixed(day(0, 13)), () => a.streakDays), 0);
      a.dispose();
    });

    test('자정을 넘겨 앱을 열어도 세션을 먼저 기록하고, 정말 빠진 날에만 얼음을 쓴다', () async {
      final st = await boot(day(-2));
      withClock(Clock.fixed(day(-2, 23)), () {
        st.setDurationMinutes(25);
        st.startTimer(allowNoTask: true);
      });
      await st.flush();
      st.dispose();

      final b = await boot(day(0));
      expect(b.sessions, hasLength(1));
      expect(b.minutesOn(dayKey(day(-2))), 25);
      expect(b.iceDays, {dayKey(day(-1))}, reason: '세션이 끝난 날은 얼음을 쓰지 않는다');
      expect(withClock(Clock.fixed(day(0)), () => b.streakDays), 1);
      b.dispose();
    });

    test('목표 달성 보상은 한 번만, 보너스 물방울은 랭킹 점수에 안 들어감', () async {
      var st = await boot(monday);
      st = await focus(st, monday, 25);
      expect(st.lastGoalRewards.map((r) => r.kind), [GoalKind.daily]);
      expect(st.drops, 25 + Growth.dailyRewardDrops);
      expect(st.rankScore, 25);

      st = await focus(st, monday.add(const Duration(hours: 1)), 25);
      expect(st.lastGoalRewards, isEmpty, reason: '오늘 목표는 이미 받음');
      expect(st.drops, 50 + Growth.dailyRewardDrops);

      st.dispose();
      final again = await boot(monday.add(const Duration(hours: 3)));
      expect(again.drops, 50 + Growth.dailyRewardDrops, reason: '재실행해도 그대로');
      again.dispose();
    });

    test('주간 목표: 얼음 지급, 이번 주 합산, 다음 주는 새로', () async {
      var st = await boot(monday);
      st = await focus(st, day(0), 60);
      st = await focus(st, day(6), 65);
      expect(st.lastGoalRewards.map((r) => r.kind), contains(GoalKind.weekly));
      expect(st.iceCount, 1, reason: '보유 1개는 지난 공백에 쓰고, 보상 1개는 남는다');
      expect(st.weekMinutes(dayKey(monday)), 125);
      expect(st.weekMinutes(dayKey(day(7))), 0);
      st.dispose();
    });

    test('얼음 구매: 물방울 차감, 최대 초과·잔액 부족은 실패', () async {
      var st = await boot(monday);
      expect(st.buyIce(), isFalse, reason: '물방울 부족');
      st = await focus(st, monday, 60);
      final drops = st.drops;
      expect(st.buyIce(), isTrue);
      expect(st.drops, drops - Growth.icePrice);
      expect(st.iceCount, 2);
      expect(st.buyIce(), isFalse, reason: '최대');
      st.dispose();
    });

    test('목표는 범위를 자르고 5분 단위로 맞춘다', () async {
      final st = await boot(monday);
      withClock(Clock.fixed(monday), () {
        st.setDailyGoal(999);
        expect(st.dailyGoal, Growth.dailyMax);
        st.setWeeklyGoal(133);
        expect(st.weeklyGoal, 135);
      });
      st.dispose();
    });
  });
}
