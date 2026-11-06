// v3 2단계: 목표·연속일·얼음·이행. 재실행해도 결과가 같아야 한다.
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/models/focus_title.dart';
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
      const bonus = 5 + Growth.dailyRewardDrops;
      var st = await boot(monday);
      st = await focus(st, monday, 25);
      expect(st.lastQuestRewards.map((r) => r.kind),
          [QuestKind.firstSession, QuestKind.dailyGoal]);
      expect(st.drops, 25 + bonus);
      expect(st.rankScore, 25);
      expect(st.unopenedChests, hasLength(2));

      st = await focus(st, monday.add(const Duration(hours: 1)), 25);
      expect(st.lastQuestRewards, isEmpty, reason: '오늘 것은 이미 받음');
      expect(st.drops, 50 + bonus);

      st.dispose();
      final again = await boot(monday.add(const Duration(hours: 3)));
      expect(again.drops, 50 + bonus, reason: '재실행해도 그대로');
      again.dispose();
    });

    test('주간 목표: 얼음 지급, 이번 주 합산, 다음 주는 새로', () async {
      var st = await boot(monday);
      st = await focus(st, day(0), 60);
      st = await focus(st, day(6), 65);
      expect(st.lastQuestRewards.map((r) => r.kind), contains(QuestKind.weeklyGoal));
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

    test('상자는 열어도 보상이 다시 나오지 않고, 다시 켜도 안 연 상태가 남는다', () async {
      var st = await boot(monday);
      st = await focus(st, monday, 25);
      final drops = st.drops;
      final keys = st.unopenedChests.toSet();
      st.dispose();

      var again = await boot(monday.add(const Duration(hours: 1)));
      expect(again.unopenedChests, keys);
      again.openChests(keys);
      expect(again.unopenedChests, isEmpty);
      expect(again.drops, drops, reason: '보상은 달성 때 이미 지급');
      await again.flush();
      again.dispose();
      again = await boot(monday.add(const Duration(hours: 2)));
      expect(again.unopenedChests, isEmpty);
      again.dispose();
    });

    test('고정 퀘스트: 하루 75분, 주 225·450분은 한 번씩만', () async {
      var st = await boot(monday);
      st = await focus(st, day(0), 75);
      expect(st.lastQuestRewards.map((r) => r.kind), [
        QuestKind.firstSession,
        QuestKind.dailyGoal,
        QuestKind.dailyLong,
      ]);
      expect(st.drops, 75 + 5 + Growth.dailyRewardDrops + 20);

      st = await focus(st, day(1), 75);
      expect(st.lastQuestRewards.map((r) => r.kind),
          contains(QuestKind.weeklyGoal));
      st = await focus(st, day(2), 75);
      expect(st.lastQuestRewards.map((r) => r.kind),
          contains(QuestKind.weeklyHalf));
      expect(st.lastQuestRewards.map((r) => r.kind),
          isNot(contains(QuestKind.weeklyFull)));

      st = await focus(st, day(3), 75);
      expect(st.lastQuestRewards.map((r) => r.kind),
          isNot(contains(QuestKind.weeklyHalf)));
      st = await focus(st, day(4), 75);
      st = await focus(st, day(5), 75);
      expect(st.lastQuestRewards.map((r) => r.kind),
          contains(QuestKind.weeklyFull));
      expect(st.weekMinutes(dayKey(monday)), 450);
      st.dispose();
    });

    test('목표가 고정 퀘스트와 같으면 목표 보상만 나간다', () {
      final rewards = <QuestReward>[];
      const Growth(daily: GoalPlan(75), weekly: GoalPlan(450)).rewardedFor(
        dayKey(monday),
        dayMinutes: 75,
        weekMinutes: 450,
        onReward: rewards.add,
      );
      expect(rewards.map((r) => r.kind), [
        QuestKind.firstSession,
        QuestKind.dailyGoal,
        QuestKind.weeklyGoal,
        QuestKind.weeklyHalf,
      ]);
    });

    test('연속 업적 90·180·365일은 그 날수에서 열린다', () async {
      Future<AppState> run(int days) async {
        await LocalStore(file()).save(
            store([for (var i = 1; i <= days; i++) session(day(-i), 25)]));
        return boot(day(0));
      }

      for (final (days, open, closed) in [
        (89, Achievement.month, Achievement.quarter),
        (90, Achievement.quarter, Achievement.halfYear),
        (180, Achievement.halfYear, Achievement.year),
        (365, Achievement.year, null),
      ]) {
        final st = await run(days);
        expect(st.hasAchievement(open), isTrue, reason: '$days일 $open');
        if (closed != null) {
          expect(st.hasAchievement(closed), isFalse, reason: '$days일 $closed');
        }
        await st.flush();
        st.dispose();
      }
    });

    test('기본 친구 4종은 처음부터 있고, 나머지는 집중으로 추가된다', () async {
      final st = await boot(monday);
      final starters = Companion.all.where((c) => c.isStarter);
      expect(starters.map((c) => c.id), ['fawn', 'rabbit', 'whale', 'puppy']);
      for (final c in Companion.all) {
        expect(st.ownedCount(c.id), c.isStarter ? 1 : 0, reason: c.id);
      }
      expect(st.place(FocusScene.daily, 'whale', 0, 0), isTrue,
          reason: '기본 친구는 다른 장면에도 놓는다');
      final ocean = Companion.forScenery(FocusScene.ocean).map((c) => c.id);
      expect(ocean.take(4).toList(), ['whale', 'fawn', 'rabbit', 'puppy'],
          reason: '이 장면 기본 친구가 맨 앞');
      expect(ocean.toSet(), hasLength(36), reason: '모든 친구가 나온다');
      st.dispose();
    });

    test('기본 친구는 세션을 끝내도 캐릭터당 1명', () async {
      var st = await boot(monday);
      st = await focus(st, day(0), 25); // 새싹사슴과 함께
      st = await focus(st, day(1), 25);
      expect(st.ownedCount('fawn'), 1);
      st.dispose();
    });

    test('기본 친구는 다른 장면으로 옮기면 그 장면에서 빠지고, 수집 친구는 보유 수까지만', () async {
      await LocalStore(file()).save(const StoreData(
          tasks: [],
          inbox: [],
          sessions: [],
          progress: Progress(owned: {
            'bear': 1
          }, placements: {
            'daily': [Placement('puppy', 0, 0)],
            'forest': [Placement('bear', 0, 0)],
          })));
      final st = await boot(monday);
      expect(
          st.setPlacements(FocusScene.ocean, const [Placement('puppy', 1, 1)]),
          isTrue);
      expect(st.placementsOf(FocusScene.daily), isEmpty);
      expect(st.placementsOf(FocusScene.ocean).single.itemId, 'puppy');
      expect(
          st.setPlacements(FocusScene.ocean, const [
            Placement('puppy', 1, 1),
            Placement('puppy', 2, 1),
          ]),
          isFalse,
          reason: '한 장면에 2명 불가');
      expect(
          st.setPlacements(FocusScene.night, const [Placement('bear', 1, 1)]),
          isFalse,
          reason: '수집 친구는 옮겨지지 않는다');
      expect(st.placementsOf(FocusScene.forest).single.itemId, 'bear');
      st.dispose();
    });

    test('총 100시간이면 다른 장면 친구까지 전부 해금', () async {
      var st = await boot(monday);
      st = await focus(st, day(0), 5999);
      expect(st.isUnlocked(Companion.byId('koala')!), isFalse);
      st = await focus(st, day(1), 1);
      expect(Companion.all.every(st.isUnlocked), isTrue);
      expect(st.hasAchievement(Achievement.allFriends), isTrue);
      st.dispose();
    });

    test('친구 그림 파일이 모두 있고 id는 서버 제한 16자 이내', () {
      for (final c in Companion.all) {
        expect(File(c.asset).existsSync(), isTrue, reason: c.asset);
        expect(c.id.length, lessThanOrEqualTo(16), reason: c.id);
      }
      expect(Companion.all.map((c) => c.id).toSet(), hasLength(36));
    });

    test('예전에 여럿 놓은 기본 친구는 1명만 남고, 수집 친구는 그대로', () async {
      await LocalStore(file()).save(const StoreData(
          tasks: [],
          inbox: [],
          sessions: [],
          progress: Progress(owned: {
            'fawn': 3,
            'bear': 2
          }, placements: {
            'forest': [
              Placement('fawn', 0, 0),
              Placement('fawn', 1, 0),
              Placement('bear', 2, 0),
              Placement('bear', 3, 0),
            ],
            'night': [Placement('fawn', 0, 0), Placement('rabbit', 1, 0)],
          })));
      final st = await boot(monday);
      expect(st.placementsOf(FocusScene.forest).map((p) => p.itemId),
          ['fawn', 'bear', 'bear']);
      expect(st.placementsOf(FocusScene.night).map((p) => p.itemId), ['rabbit']);
      expect(
          st.setPlacements(
              FocusScene.forest, st.placementsOf(FocusScene.forest)),
          isTrue,
          reason: '정리 후 편집이 막히지 않는다');
      st.dispose();
    });

    test('도감 조건 상향: 300·1200·3000분, 이미 만난 친구는 유지', () async {
      final squirrel = Companion.byId('squirrel')!;
      var st = await boot(monday);
      st = await focus(st, day(0), 299);
      expect(st.isUnlocked(squirrel), isFalse);
      st = await focus(st, day(1), 1);
      expect(st.isUnlocked(squirrel), isTrue);
      st.dispose();
      for (final scene in FocusScene.values) {
        expect(Companion.of(scene).map((c) => c.unlockMinutes),
            [0, 150, 300, 450, 600, 800, 1000, 1250, 1500]);
      }
      expect(Companion.all, hasLength(36));

      await LocalStore(file()).save(const StoreData(
          tasks: [],
          inbox: [],
          sessions: [],
          progress: Progress(owned: {'bear': 2})));
      final old = await boot(day(2));
      expect(old.isUnlocked(Companion.byId('bear')!), isTrue);
      expect(old.isUnlocked(Companion.byId('fox')!), isFalse);
      expect(old.hasAchievement(Achievement.allFriends), isFalse);
      old.dispose();
    });

    test('구버전 파일을 읽고 저장해도 앱 잠금 설정이 유지된다', () async {
      await file().writeAsString(jsonEncode({
        'tasks': [],
        'inbox': [],
        'sessions': [],
        'progress': {'lockEnabled': true, 'drops': 7}, // growth 없는 1.0.x 파일
      }));
      final a = await boot(monday);
      expect(a.lockEnabled, isTrue);
      a.setLockEnabled(true);
      await a.flush();
      a.dispose();
      final b = await boot(monday.add(const Duration(hours: 1)));
      expect(b.lockEnabled, isTrue);
      expect(b.drops, 7);
      b.dispose();
    });

    test('친구 성장은 그 친구와 끝까지 한 분만, 중단은 빼고', () async {
      final st = await boot(monday);
      expect(st.companionStage('fawn'), CompanionStage.basic);
      var s2 = await focus(st, day(0), 120);
      expect(s2.companionMinutes('fawn'), 120);
      expect(s2.companionStage('fawn'), CompanionStage.sprout);
      expect(s2.companionMinutes('rabbit'), 0);
      s2.dispose();
    });

    test('업적: 첫 완료는 끝까지 한 집중만', () async {
      await LocalStore(file()).save(
          store([session(day(-1), 5, o: SessionOutcome.abandoned)]));
      var st = await boot(monday);
      expect(st.hasAchievement(Achievement.firstFocus), isFalse);
      st = await focus(st, monday, 25);
      expect(st.hasAchievement(Achievement.firstFocus), isTrue);
      expect(st.hasAchievement(Achievement.week), isFalse);
      st.dispose();
    });
  });

  group('성장 지도', () {
    test('칸은 XP 오름차순이고 칭호 문턱을 모두 포함', () {
      final xps = MapNode.all.map((n) => n.xp).toList();
      expect(xps, orderedEquals([...xps]..sort()));
      for (final t in FocusTitle.values) {
        expect(MapNode.all.where((n) => n.title == t).single.xp, t.minMinutes);
      }
    });
    test('현재 칸은 아직 닿지 않은 첫 칸, 끝나면 마지막', () {
      expect(MapNode.all[MapNode.currentIndex(0)].xp, 30);
      expect(MapNode.all[MapNode.currentIndex(29)].xp, 30);
      expect(MapNode.all[MapNode.currentIndex(30)].xp, 65);
      expect(MapNode.currentIndex(999999), MapNode.all.length - 1);
    });
    test('레벨: 칸 수가 적고 칸 번호와 같으며 위로 갈수록 간격이 넓다', () {
      expect(MapNode.all.length, lessThanOrEqualTo(70));
      expect(MapNode.levelOf(0), 1);
      expect(MapNode.levelOf(29), 1);
      expect(MapNode.levelOf(30), 2);
      for (final n in MapNode.all) {
        expect(MapNode.levelOf(n.xp), n.level);
        expect(n.xp % 5, 0, reason: '시간 링이 5분 단위');
      }
      expect(MapNode.levelOf(999999), MapNode.all.length);
      final gap = [
        for (var i = 1; i < MapNode.all.length; i++)
          MapNode.all[i].xp - MapNode.all[i - 1].xp
      ];
      expect(gap.last, greaterThan(gap.first * 10));
    });
  });
}
