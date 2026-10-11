// lib/services/ranking_service.dart
// 폰 랭킹: Supabase 익명 계정 + 닉네임. 서버 규칙은 supabase/migrations/*_leaderboard.sql
// (하루 +720 상한, 직전 제출 뒤 흐른 분 이상 못 오름, 비상 탈출은 감점).
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RankRow = ({int rank, String nickname, int points, bool isMe});

class RankingService {
  // 공개용(publishable) 키 — 앱에 들어가도 되는 값. 권한은 서버 함수가 판단.
  static const _url = 'https://bvnwdbbjkrjdqgqyidhp.supabase.co';
  static const _key = 'sb_publishable_FpZ0R1WhUORMPvcB-L0JzQ_9EVDgMT9';

  static Future<void> init() => Supabase.initialize(url: _url, publishableKey: _key);

  SupabaseClient get _db => Supabase.instance.client;

  Future<void> _signIn() async {
    if (_db.auth.currentSession == null) await _db.auth.signInAnonymously();
  }

  Future<void> submit(int total, String nickname) async {
    await _signIn();
    await _db.rpc('submit_score',
        params: {'p_total': total, 'p_nickname': nickname});
  }

  Future<List<RankRow>> ranking({required bool week}) async {
    await _signIn();
    final rows = await _db.rpc('ranking', params: {'p_week': week}) as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        (
          rank: (r['rank'] as num).toInt(),
          nickname: r['nickname'] as String,
          points: (r['points'] as num).toInt(),
          isMe: r['is_me'] as bool,
        )
    ];
  }

  Future<void> leave() async {
    await _signIn();
    await _db.rpc('leave_ranking');
  }
}
