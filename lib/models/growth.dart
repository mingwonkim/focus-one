// lib/models/growth.dart
// 폰 v3 성장: 목표·연속일·얼음. 계산은 전부 순수 함수이고 저장은 Progress.growth 한 덩어리.
// XP·칭호는 저장하지 않는다 — 완료 세션에서 계산한다 (docs/v3/app-design-spec.md §1, §6).
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

  final String? migratedOn; // null = 아직 이행 전
  final String? evaluatedThrough; // 이 날까지 얼음 사용을 판단했다
  final int ice;
  final Set<String> iceDays;
  final GoalPlan daily;
  final GoalPlan weekly;
  final Set<String> rewarded; // 'daily:<날짜>' · 'weekly:<월요일>'

  const Growth({
    this.migratedOn,
    this.evaluatedThrough,
    this.ice = 0,
    this.iceDays = const {},
    this.daily = const GoalPlan(dailyDefault),
    this.weekly = const GoalPlan(weeklyDefault),
    this.rewarded = const {},
  });

  Growth copyWith({
    String? migratedOn,
    String? evaluatedThrough,
    int? ice,
    Set<String>? iceDays,
    GoalPlan? daily,
    GoalPlan? weekly,
    Set<String>? rewarded,
  }) =>
      Growth(
        migratedOn: migratedOn ?? this.migratedOn,
        evaluatedThrough: evaluatedThrough ?? this.evaluatedThrough,
        ice: ice ?? this.ice,
        iceDays: iceDays ?? this.iceDays,
        daily: daily ?? this.daily,
        weekly: weekly ?? this.weekly,
        rewarded: rewarded ?? this.rewarded,
      );

  Map<String, dynamic> toJson() => {
        'migratedOn': migratedOn,
        'evaluatedThrough': evaluatedThrough,
        'ice': ice,
        'iceDays': iceDays.toList(),
        'daily': daily.toJson(),
        'weekly': weekly.toJson(),
        'rewarded': rewarded.toList(),
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

  /// 이번 달성으로 새로 받을 보상. 받은 키는 다시 나오지 않는다.
  Growth rewardedFor(
    String day, {
    required int dayMinutes,
    required int weekMinutes,
    required void Function(GoalReward) onReward,
  }) {
    var g = this;
    final dailyKey = 'daily:$day';
    if (dayMinutes >= daily.on(day) && !rewarded.contains(dailyKey)) {
      g = g.copyWith(rewarded: {...g.rewarded, dailyKey});
      onReward(const GoalReward(GoalKind.daily, dailyRewardDrops, 0));
    }
    final week = weekKey(day);
    final weeklyKey = 'weekly:$week';
    if (weekMinutes >= weekly.on(week) && !rewarded.contains(weeklyKey)) {
      final gained = ice < iceMax ? 1 : 0;
      g = g.copyWith(
          rewarded: {...g.rewarded, weeklyKey}, ice: g.ice + gained);
      onReward(GoalReward(GoalKind.weekly, weeklyRewardDrops, gained));
    }
    return g;
  }
}

enum GoalKind { daily, weekly }

class GoalReward {
  final GoalKind kind;
  final int drops;
  final int ice;
  const GoalReward(this.kind, this.drops, this.ice);
}
