// lib/services/ranking_service.dart
// 폰 랭킹·명예의 전당: Supabase 익명 계정 + 닉네임 + 아바타(친구 id).
// 서버 규칙은 supabase/migrations/ (하루 +720 상한, 직전 제출 뒤 흐른 분 이상 못 오름,
// 비상 탈출은 감점, 칭호는 서버가 인정한 누적 분 total_minutes 기준).
import 'package:supabase_flutter/supabase_flutter.dart';

enum RankPeriod { week, month, all }

typedef RankRow = ({
  int rank,
  String nickname,
  String avatar,
  int points,
  int totalMinutes,
  bool isMe,
});

class RankingService {
  // 공개용(publishable) 키 — 앱에 들어가도 되는 값. 권한은 서버 함수가 판단.
  static const _url = 'https://bvnwdbbjkrjdqgqyidhp.supabase.co';
  static const _key = 'sb_publishable_FpZ0R1WhUORMPvcB-L0JzQ_9EVDgMT9';

  static Future<void> init() => Supabase.initialize(url: _url, publishableKey: _key);

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> _signIn() async {
    if (_db.auth.currentSession == null) await _db.auth.signInAnonymously();
  }

  Future<void> submit(int total, String nickname, String avatar) async {
    await _signIn();
    await _db.rpc('submit_score',
        params: {'p_total': total, 'p_nickname': nickname, 'p_avatar': avatar});
  }

  RankRow _row(Map<String, dynamic> r) => (
        rank: (r['rank'] as num).toInt(),
        nickname: r['nickname'] as String,
        avatar: r['avatar'] as String? ?? '',
        points: (r['points'] as num).toInt(),
        totalMinutes: (r['total_minutes'] as num).toInt(),
        isMe: r['is_me'] as bool? ?? false,
      );

  Future<List<RankRow>> ranking(RankPeriod period) async {
    await _signIn();
    final rows =
        await _db.rpc('ranking', params: {'p_period': period.name}) as List;
    return [for (final r in rows.cast<Map<String, dynamic>>()) _row(r)];
  }

  /// 바로 지난 주/달의 1~3위 (누적엔 없음)
  Future<List<RankRow>> pastWinners(RankPeriod period) async {
    if (period == RankPeriod.all) return const [];
    await _signIn();
    final rows =
        await _db.rpc('past_winners', params: {'p_period': period.name}) as List;
    return [for (final r in rows.cast<Map<String, dynamic>>()) _row(r)];
  }

  Future<void> leave() async {
    await _signIn();
    await _db.rpc('leave_ranking');
  }
}
