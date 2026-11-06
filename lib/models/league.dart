// lib/models/league.dart
// 주간 리그 화면 값. 규칙의 원본은 supabase/migrations/20261107000000_league.sql.

enum LeagueTier {
  walk('산책'),
  explore('탐험'),
  voyage('항해');

  const LeagueTier(this.label);
  final String label;

  static LeagueTier of(int i) => values[i.clamp(0, values.length - 1)];
}

class LeagueRow {
  final int rank;
  final String nickname;
  final String avatar;
  final int minutes;
  final int totalMinutes;
  final bool isMe;

  const LeagueRow({
    required this.rank,
    required this.nickname,
    required this.avatar,
    required this.minutes,
    required this.totalMinutes,
    required this.isMe,
  });

  factory LeagueRow.fromJson(Map<String, dynamic> j) => LeagueRow(
        rank: (j['rank'] as num).toInt(),
        nickname: j['nickname'] as String,
        avatar: j['avatar'] as String? ?? '',
        minutes: (j['minutes'] as num).toInt(),
        totalMinutes: (j['total_minutes'] as num).toInt(),
        isMe: j['is_me'] as bool? ?? false,
      );
}

class LeagueResult {
  final String week;
  final int rank;
  final int groupSize;
  final int minutes;
  final LeagueTier from;
  final LeagueTier to;

  const LeagueResult({
    required this.week,
    required this.rank,
    required this.groupSize,
    required this.minutes,
    required this.from,
    required this.to,
  });

  factory LeagueResult.fromJson(Map<String, dynamic> j) => LeagueResult(
        week: j['week'] as String,
        rank: (j['rank'] as num).toInt(),
        groupSize: (j['group_size'] as num).toInt(),
        minutes: (j['minutes'] as num).toInt(),
        from: LeagueTier.of((j['from_tier'] as num).toInt()),
        to: LeagueTier.of((j['to_tier'] as num).toInt()),
      );
}

class LeagueStatus {
  final bool joined;
  final LeagueTier tier;
  final String? week;
  final List<LeagueRow> board;
  final LeagueResult? lastResult;

  const LeagueStatus({
    required this.joined,
    this.tier = LeagueTier.walk,
    this.week,
    this.board = const [],
    this.lastResult,
  });

  factory LeagueStatus.fromJson(Map<String, dynamic> j) {
    if (j['joined'] != true) return const LeagueStatus(joined: false);
    final last = j['last_result'] as Map<String, dynamic>?;
    return LeagueStatus(
      joined: true,
      tier: LeagueTier.of((j['tier'] as num).toInt()),
      week: j['week'] as String?,
      board: [
        for (final r in (j['board'] as List? ?? const []))
          LeagueRow.fromJson(r as Map<String, dynamic>)
      ],
      lastResult: last == null ? null : LeagueResult.fromJson(last),
    );
  }

  /// 소규모 조(3명 이하)는 이 분을 채우면 승급
  static const smallGroupGoal = 150;
  bool get smallGroup => board.length <= 3;

  /// 서버 정산과 같은 규칙: 상위 ceil(20%) 등수 안(동점 전원)이고 1분 이상이면 승급
  int get promoteCount {
    if (tier == LeagueTier.voyage || smallGroup) return 0;
    final up = (board.length * 0.2).ceil();
    return board.where((r) => r.minutes > 0 && r.rank <= up).length;
  }

  /// 아래에서 floor(20%)+1번째 점수보다 낮으면 강등 (선 동점은 빠진다)
  int get demoteCount {
    if (tier == LeagueTier.walk || smallGroup) return 0;
    final down = (board.length * 0.2).floor();
    if (down == 0) return 0;
    final minutes = [for (final r in board) r.minutes]..sort();
    final line = minutes[down];
    return minutes.where((m) => m < line).length;
  }
}
