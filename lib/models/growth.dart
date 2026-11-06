// lib/models/growth.dart
// 폰 v3 성장: 목표·연속일·얼음. 계산은 전부 순수 함수이고 저장은 Progress.growth 한 덩어리.
// XP·칭호는 저장하지 않는다 — 완료 세션에서 계산한다 (docs/v3/app-design-spec.md §1, §6).
import 'focus_title.dart';
import 'task.dart';

/// 하루를 가리키는 키 (기기 시각 기준 yyyy-MM-dd). 문자열 비교가 곧 날짜 비교다.
String dayKey(DateTime t) => '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

DateTime parseDay(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String addDays(String key, int days) {
  final d = parseDay(key);
  return dayKey(DateTime(d.year, d.month, d.day + days));
}

/// 그 주 월요일의 키
String weekKey(String key) =>
    addDays(key, -(parseDay(key).weekday - DateTime.monday));

/// 목표 하나. 낮춘 값은 다음 기간부터 적용되므로 예약을 함께 들고 있다.
class GoalPlan {
  final int minutes;
  final int? nextMinutes;
  final String? nextFrom;

  const GoalPlan(this.minutes, {this.nextMinutes, this.nextFrom});

  int on(String day) =>
      nextFrom != null && day.compareTo(nextFrom!) >= 0 ? nextMinutes! : minutes;

  /// 오늘 기준 다음 값. [from]은 낮출 때 적용될 다음 기간 첫날.
  GoalPlan changed(int value, {required String today, required String from}) {
    final now = on(today);
    if (value >= now) return GoalPlan(value); // 올리면 바로, 원래 값이면 예약 취소
    return GoalPlan(now, nextMinutes: value, nextFrom: from);
  }

  Map<String, dynamic> toJson() =>
      {'minutes': minutes, 'nextMinutes': nextMinutes, 'nextFrom': nextFrom};

  factory GoalPlan.fromJson(Map<String, dynamic>? j, int fallback) => GoalPlan(
        j?['minutes'] as int? ?? fallback,
        nextMinutes: j?['nextMinutes'] as int?,
        nextFrom: j?['nextFrom'] as String?,
      );
}

class Growth {
  static const dailyDefault = 25;
  static const weeklyDefault = 125;
  static const dailyMin = 10;
  static const dailyMax = 180;
  static const weeklyMin = 25;
  static const weeklyMax = 1260;
  static const goalStep = 5;
  static const iceMax = 2;
  static const icePrice = 30;
  static const dailyRewardDrops = 10;
  static const weeklyRewardDrops = 30;
  static const longDayMinutes = 75; // 고정 퀘스트 기준: 하루 75분

  final String? migratedOn; // null = 아직 이행 전
  final String? evaluatedThrough; // 이 날까지 얼음 사용을 판단했다
  final int ice;
  final Set<String> iceDays;
  final GoalPlan daily;
  final GoalPlan weekly;
  final Set<String> rewarded; // QuestKind.keyFor: 'first:<날짜>' · 'weekly:<월요일>' 등
  final Set<String> unopened; // 아직 안 연 상자
  final bool leagueJoined; // 서버 리그 참여 (서버가 원본, 화면 열 때 맞춘다)
  final Set<String> leagueOutbox; // 끝났지만 서버에 아직 못 보낸 세션 id

  const Growth({
    this.migratedOn,
    this.evaluatedThrough,
    this.ice = 0,
    this.iceDays = const {},
    this.daily = const GoalPlan(dailyDefault),
    this.weekly = const GoalPlan(weeklyDefault),
    this.rewarded = const {},
    this.unopened = const {},
    this.leagueJoined = false,
    this.leagueOutbox = const {},
  });

  Growth copyWith({
    String? migratedOn,
    String? evaluatedThrough,
    int? ice,
    Set<String>? iceDays,
    GoalPlan? daily,
    GoalPlan? weekly,
    Set<String>? rewarded,
    Set<String>? unopened,
    bool? leagueJoined,
    Set<String>? leagueOutbox,
  }) =>
      Growth(
        migratedOn: migratedOn ?? this.migratedOn,
        evaluatedThrough: evaluatedThrough ?? this.evaluatedThrough,
        ice: ice ?? this.ice,
        iceDays: iceDays ?? this.iceDays,
        daily: daily ?? this.daily,
        weekly: weekly ?? this.weekly,
        rewarded: rewarded ?? this.rewarded,
        unopened: unopened ?? this.unopened,
        leagueJoined: leagueJoined ?? this.leagueJoined,
        leagueOutbox: leagueOutbox ?? this.leagueOutbox,
      );

  Map<String, dynamic> toJson() => {
        'migratedOn': migratedOn,
        'evaluatedThrough': evaluatedThrough,
        'ice': ice,
        'iceDays': iceDays.toList(),
        'daily': daily.toJson(),
        'weekly': weekly.toJson(),
        'rewarded': rewarded.toList(),
        'unopened': unopened.toList(),
        'leagueJoined': leagueJoined,
        'leagueOutbox': leagueOutbox.toList(),
      };

  factory Growth.fromJson(Map<String, dynamic>? j) => Growth(
        migratedOn: j?['migratedOn'] as String?,
        evaluatedThrough: j?['evaluatedThrough'] as String?,
        ice: j?['ice'] as int? ?? 0,
        iceDays: {...(j?['iceDays'] as List? ?? const []).cast<String>()},
        daily: GoalPlan.fromJson(
            j?['daily'] as Map<String, dynamic>?, dailyDefault),
        weekly: GoalPlan.fromJson(
            j?['weekly'] as Map<String, dynamic>?, weeklyDefault),
        rewarded: {...(j?['rewarded'] as List? ?? const []).cast<String>()},
        unopened: {...(j?['unopened'] as List? ?? const []).cast<String>()},
        leagueJoined: j?['leagueJoined'] as bool? ?? false,
        leagueOutbox: {...(j?['leagueOutbox'] as List? ?? const []).cast<String>()},
      );

  /// 이행: 지난 날에는 얼음을 소급해 쓰지 않는다. 여러 번 불러도 같다.
  Growth migrated(String today) => migratedOn != null
      ? this
      : copyWith(
          migratedOn: today,
          evaluatedThrough: addDays(today, -1),
          ice: iceMax - 1,
        );

  /// 연속일로 인정되는 날. 이행 전 기록은 기존 규칙(중단도 인정)을 그대로 둔다.
  Set<String> activeDays(Iterable<FocusSession> sessions) => {
        for (final s in sessions)
          if (s.outcome != SessionOutcome.abandoned ||
              (migratedOn != null &&
                  dayKey(s.endedAt).compareTo(migratedOn!) < 0))
            dayKey(s.endedAt)
      };

  int _runEndingAt(String day, Set<String> active) {
    var count = 0;
    var d = day;
    while (true) {
      if (active.contains(d)) {
        count++;
      } else if (!iceDays.contains(d)) {
        return count;
      }
      d = addDays(d, -1);
    }
  }

  /// 오늘 집중 전이면 어제까지의 연속을 유지해 보여 준다.
  int streak(String today, Set<String> active) => _runEndingAt(
      active.contains(today) ? today : addDays(today, -1), active);

  int bestStreak(Set<String> active) {
    var best = 0;
    for (final d in active) {
      if (active.contains(addDays(d, 1))) continue; // 구간의 끝에서만 센다
      final run = _runEndingAt(d, active);
      if (run > best) best = run;
    }
    return best;
  }

  /// 어제까지 빠진 날에 얼음을 쓴다. 이미 판단한 날은 다시 보지 않으므로 몇 번 불러도 같다.
  Growth settled(String today, Set<String> active) {
    final through = addDays(today, -1);
    if (evaluatedThrough == null ||
        evaluatedThrough!.compareTo(through) >= 0) {
      return this;
    }
    var g = this;
    for (var d = addDays(evaluatedThrough!, 1);
        d.compareTo(through) <= 0 && g.ice > 0;
        d = addDays(d, 1)) {
      if (!active.contains(d) && g._runEndingAt(addDays(d, -1), active) > 0) {
        g = g.copyWith(ice: g.ice - 1, iceDays: {...g.iceDays, d});
      }
    }
    return g.copyWith(evaluatedThrough: through);
  }

  /// 이번 완료로 새로 받을 보상. 받은 키는 다시 나오지 않고, 상자는 열 때까지 남는다.
  /// 보상은 달성 순간 확정이며 여는 건 연출일 뿐이다.
  Growth rewardedFor(
    String day, {
    required int dayMinutes,
    required int weekMinutes,
    required void Function(QuestReward) onReward,
  }) {
    var g = this;
    void grant(QuestKind kind, String period) {
      final key = kind.keyFor(period);
      if (g.rewarded.contains(key)) return;
      final gainedIce =
          kind == QuestKind.weeklyGoal && g.ice < iceMax ? 1 : 0;
      g = g.copyWith(
        rewarded: {...g.rewarded, key},
        unopened: {...g.unopened, key},
        ice: g.ice + gainedIce,
      );
      onReward(QuestReward(kind, key, kind.drops, gainedIce));
    }

    grant(QuestKind.firstSession, day);
    final dayGoal = daily.on(day);
    if (dayMinutes >= dayGoal) grant(QuestKind.dailyGoal, day);
    // 내 목표와 같은 분량의 고정 퀘스트는 겹치므로 목표 쪽만 준다
    const long = QuestKind.dailyLong;
    if (long.minutes != dayGoal && dayMinutes >= long.minutes!) grant(long, day);
    final week = weekKey(day);
    final weekGoal = weekly.on(week);
    if (weekMinutes >= weekGoal) grant(QuestKind.weeklyGoal, week);
    for (final q in [QuestKind.weeklyHalf, QuestKind.weeklyFull]) {
      if (q.minutes != weekGoal && weekMinutes >= q.minutes!) grant(q, week);
    }
    return g;
  }

  Growth opened(Iterable<String> keys) =>
      copyWith(unopened: unopened.difference(keys.toSet()));
}

enum QuestKind {
  firstSession(5, 'first'),
  dailyGoal(Growth.dailyRewardDrops, 'daily'),
  dailyLong(20, 'daily75', minutes: Growth.longDayMinutes),
  weeklyGoal(Growth.weeklyRewardDrops, 'weekly'),
  weeklyHalf(40, 'weekly225', minutes: Growth.longDayMinutes * 3),
  weeklyFull(80, 'weekly450', minutes: Growth.longDayMinutes * 6);

  const QuestKind(this.drops, this.prefix, {this.minutes});
  final int drops;
  final String prefix;
  final int? minutes; // 고정 분량 퀘스트만

  /// [period]: 날짜 또는 그 주 월요일
  String keyFor(String period) => '$prefix:$period';
}

class QuestReward {
  final QuestKind kind;
  final String key;
  final int drops;
  final int ice;
  const QuestReward(this.kind, this.key, this.drops, this.ice);
}

/// 성장 지도의 칸 = 레벨. 위로 갈수록 필요한 분이 늘고, 칭호 문턱은 가장 가까운 칸을 대신하는
/// 큰 칸이다. XP에서 계산하므로 저장하지 않는다.
class MapNode {
  final int xp;
  final int level;
  final FocusTitle? title;
  const MapNode(this.xp, this.level, this.title);

  static const firstGap = 25;
  static const gapGrowth = 15;

  static final List<MapNode> all = () {
    final top = FocusTitle.master.minMinutes;
    final xps = <int>[0];
    for (var gap = firstGap; xps.last + gap < top; gap += gapGrowth) {
      xps.add(xps.last + gap);
    }
    final titles = <int, FocusTitle>{};
    for (final t in FocusTitle.values) {
      var near = 0;
      for (var i = 1; i < xps.length; i++) {
        if ((xps[i] - t.minMinutes).abs() < (xps[near] - t.minMinutes).abs()) {
          near = i;
        }
      }
      xps[near] = t.minMinutes;
      titles[t.minMinutes] = t;
    }
    return [
      for (var i = 0; i < xps.length; i++) MapNode(xps[i], i + 1, titles[xps[i]])
    ];
  }();

  /// 지금 레벨: 이미 닿은 칸 수
  static int levelOf(int xp) => all.where((n) => n.xp <= xp).length;

  /// 아직 닿지 않은 첫 칸. 끝까지 갔으면 마지막 칸.
  static int currentIndex(int xp) {
    final i = all.indexWhere((n) => n.xp > xp);
    return i < 0 ? all.length - 1 : i;
  }
}

/// 친구 성장: 그 친구와 끝까지 완료한 누적 분. 능력치 없음, 내려가지 않음.
enum CompanionStage {
  basic('만남', 0),
  sprout('단짝', 120),
  glow('빛나는 단짝', 600);

  const CompanionStage(this.label, this.minMinutes);
  final String label;
  final int minMinutes;

  static CompanionStage of(int minutes) =>
      values.lastWhere((s) => minutes >= s.minMinutes);

  CompanionStage? get next =>
      this == glow ? null : values[index + 1];
}

/// 업적: 재화 없음, 기록에서 계산
enum Achievement {
  firstFocus('첫 집중', '집중을 처음 끝까지 해냈어요'),
  week('7일 연속', '7일 연속 집중했어요'),
  month('30일 연속', '30일 연속 집중했어요'),
  quarter('90일 연속', '90일 연속 집중했어요'),
  halfYear('180일 연속', '180일 연속 집중했어요'),
  year('365일 연속', '365일 연속 집중했어요'),
  allFriends('모든 친구', '친구 16종을 모두 만날 수 있어요');

  const Achievement(this.label, this.detail);
  final String label;
  final String detail;
}
