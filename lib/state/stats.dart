// lib/state/stats.dart
// 기록 탭 계산. 실집중 구간 = [끝난 시각 - 실집중초, 끝난 시각] 을 현지 시각으로 날·시간 경계에서 나눈다.
// ponytail: 일시정지 구간은 무시하고 끝 시각 기준으로 몰아 계산 — 일시정지 타임라인을 저장하면 정밀화.
import '../models/task.dart';

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

class FocusStats {
  FocusStats(this.sessions);

  final List<FocusSession> sessions;

  /// 실집중 구간을 [unit] 경계로 잘라 (구간 시작, 초) 목록으로. 구기록(실집중초 없음)은 끝 시각에 통째로.
  Iterable<(DateTime, int)> _pieces(FocusSession s, {required bool hourly}) sync* {
    final sec = s.focusedSec ?? s.minutes * 60;
    if (sec <= 0) return;
    if (s.focusedSec == null) {
      if (!hourly) yield (_day(s.endedAt), sec);
      return; // 시간대 분할 불가 → 골든타임에서 제외
    }
    var cur = s.endedAt.subtract(Duration(seconds: sec));
    while (cur.isBefore(s.endedAt)) {
      final bucket = hourly
          ? DateTime(cur.year, cur.month, cur.day, cur.hour)
          : _day(cur);
      final next = hourly
          ? bucket.add(const Duration(hours: 1))
          : DateTime(bucket.year, bucket.month, bucket.day + 1);
      final end = next.isBefore(s.endedAt) ? next : s.endedAt;
      yield (bucket, end.difference(cur).inSeconds);
      cur = end;
    }
  }

  /// 날짜(자정) → 실집중 초. 그만두기·조기 완료도 집중한 시간은 포함.
  Map<DateTime, int> daily() {
    final m = <DateTime, int>{};
    for (final s in sessions) {
      for (final (d, sec) in _pieces(s, hourly: false)) {
        m[d] = (m[d] ?? 0) + sec;
      }
    }
    return m;
  }

  /// [from, to) 범위의 일별 합 (막대 그래프)
  List<int> range(DateTime from, int days) {
    final d = daily();
    return [
      for (var i = 0; i < days; i++)
        d[DateTime(from.year, from.month, from.day + i)] ?? 0
    ];
  }

  /// 연도의 월별 합
  List<int> months(int year) {
    final out = List.filled(12, 0);
    daily().forEach((d, sec) {
      if (d.year == year) out[d.month - 1] += sec;
    });
    return out;
  }

  /// 연속일: 하루 실집중 1분 이상인 날이 오늘(또는 어제)부터 이어진 수
  int streak(DateTime now) {
    final d = daily();
    bool ok(DateTime day) => (d[day] ?? 0) >= 60;
    var cur = _day(now);
    if (!ok(cur)) cur = DateTime(cur.year, cur.month, cur.day - 1);
    var n = 0;
    while (ok(cur)) {
      n++;
      cur = DateTime(cur.year, cur.month, cur.day - 1);
    }
    return n;
  }

  /// 완료 횟수 (끝까지 한 세션만)
  int completedCount(DateTime from, DateTime to) => sessions
      .where((s) =>
          s.outcome == SessionOutcome.completed &&
          !s.endedAt.isBefore(from) &&
          s.endedAt.isBefore(to))
      .length;

  /// 태그 id(없으면 '') → 초, [from, to) 범위
  Map<String, int> byTag(DateTime from, DateTime to) {
    final m = <String, int>{};
    for (final s in sessions) {
      for (final (d, sec) in _pieces(s, hourly: false)) {
        if (d.isBefore(from) || !d.isBefore(to)) continue;
        final k = s.tagId ?? '';
        m[k] = (m[k] ?? 0) + sec;
      }
    }
    return m;
  }

  /// 잔디: 최근 [weeks]주 날짜별 단계 0~4 (0 / ~25분 / ~60분 / ~120분 / 그 이상)
  Map<DateTime, int> heatmap(DateTime now, {int weeks = 26}) {
    final d = daily();
    final start = DateTime(now.year, now.month, now.day - weeks * 7 + 1);
    return {
      for (var i = 0; i < weeks * 7; i++)
        DateTime(start.year, start.month, start.day + i): _level(
            d[DateTime(start.year, start.month, start.day + i)] ?? 0),
    };
  }

  static int _level(int sec) => sec == 0
      ? 0
      : sec < 25 * 60
          ? 1
          : sec < 60 * 60
              ? 2
              : sec < 120 * 60
                  ? 3
                  : 4;

  /// 골든타임: 최근 [days]일 동안 시간대(0~23시)별 일평균 실집중이 가장 큰 시각들(동률 병기). 기록 없으면 빈 목록.
  List<int> goldenHours(DateTime now, {int days = 28}) {
    final from = DateTime(now.year, now.month, now.day - days + 1);
    final perHour = List.filled(24, 0);
    for (final s in sessions) {
      for (final (h, sec) in _pieces(s, hourly: true)) {
        if (!h.isBefore(from)) perHour[h.hour] += sec;
      }
    }
    final best = perHour.reduce((a, b) => a > b ? a : b);
    if (best == 0) return const [];
    return [for (var h = 0; h < 24; h++) if (perHour[h] == best) h];
  }
}
