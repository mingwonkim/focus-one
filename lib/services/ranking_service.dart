// lib/services/ranking_service.dart
// 폰 랭킹·명예의 전당: Supabase 익명 계정 + 닉네임 + 아바타(친구 id).
// 서버 규칙은 supabase/migrations/ (하루 +720 상한, 직전 제출 뒤 흐른 분 이상 못 오름,
// 비상 탈출은 감점, 칭호는 서버가 인정한 누적 분 total_minutes 기준).
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/league.dart';

enum RankPeriod { week, month, all }

typedef RankRow = ({
  int rank,
  String nickname,
  String avatar,
  int points,
  int totalMinutes,
  bool isMe,
});

/// 친구 1명과의 이번 주 대결. code = 상대 초대 코드(끊기용)
typedef Duel = ({
  String code,
  String nickname,
  String avatar,
  int totalMinutes,
  int myWeek,
  int theirWeek,
  int wins,
  int losses,
  int draws,
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

  /// 내 초대 코드 (카톡 초대 링크에 실림)
  Future<String> inviteCode() async {
    await _signIn();
    return await _db.rpc('my_invite_code') as String;
  }

  /// 초대 수락 → 상대 닉네임. 서버 오류: bad code / own code / join first / too many friends
  Future<String> acceptInvite(String code) async {
    await _signIn();
    return await _db.rpc('accept_invite', params: {'p_code': code}) as String;
  }

  /// 친구별 이번 주 1:1 대결 + 지난 주까지 전적
  Future<List<Duel>> duels() async {
    await _signIn();
    final rows = await _db.rpc('duels') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        (
          code: r['code'] as String,
          nickname: r['nickname'] as String,
          avatar: r['avatar'] as String? ?? '',
          totalMinutes: (r['total_minutes'] as num).toInt(),
          myWeek: (r['my_week'] as num).toInt(),
          theirWeek: (r['their_week'] as num).toInt(),
          wins: (r['wins'] as num).toInt(),
          losses: (r['losses'] as num).toInt(),
          draws: (r['draws'] as num).toInt(),
        )
    ];
  }

  // ---- 주간 리그 (점수는 서버 시계로 잰 세션만) ----
  Future<LeagueStatus> leagueStatus() async {
    await _signIn();
    final j = await _db.rpc('league_status') as Map<String, dynamic>;
    return LeagueStatus.fromJson(j);
  }

  /// 서버 오류: join first (명예의 전당 닉네임 필요)
  Future<void> joinLeague() async {
    await _signIn();
    await _db.rpc('join_league');
  }

  Future<void> leaveLeague() async {
    await _signIn();
    await _db.rpc('leave_league');
  }

  Future<void> beginFocus(String sessionId, int plannedSec) async {
    await _signIn();
    await _db.rpc('begin_focus_v3',
        params: {'p_session': sessionId, 'p_planned_sec': plannedSec});
  }

  /// 인정된 분을 돌려준다. 예약이 없거나 마감이 지났으면 0. 서버 오류: too early
  Future<int> finishFocus(String sessionId) async {
    await _signIn();
    return (await _db.rpc('finish_focus_v3', params: {'p_session': sessionId})
            as num)
        .toInt();
  }

  Future<void> removeFriend(String code) async {
    await _signIn();
    await _db.rpc('remove_friend', params: {'p_code': code});
  }

  /// 익명 계정과 점수를 서버에서 완전히 지운다 (leave_ranking이 auth.users 삭제 → cascade)
  Future<void> leave() async {
    if (_db.auth.currentSession == null) return; // 계정이 만들어진 적 없음
    await _db.rpc('leave_ranking');
    await _db.auth.signOut(scope: SignOutScope.local); // 서버 계정은 이미 지워짐
  }
}
