// lib/mobile/records/ranking_page.dart
// 기록 탭 → 랭킹. 참여 전엔 안내 + 닉네임, 참여 후엔 이번 주/누적 순위.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../models/collection.dart';
import '../../services/ranking_service.dart';
import '../../state/app_state.dart';
import '../adaptive.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

// 닉네임은 정해진 단어 조합에서만 고른다 — 자유 입력(사용자 생성 콘텐츠)이면 신고·차단 기능이 필요해서
const _adjectives = ['졸린', '느긋한', '부지런한', '반짝이는', '조용한', '용감한', '꿈꾸는', '씩씩한', '포근한', '단단한'];

final _privacyUrl = Uri.parse('https://looinlabs.com/fokko/privacy');

Widget _privacyLink(SceneStyle style) => Center(
      child: TextButton(
        onPressed: () => launchUrl(_privacyUrl),
        child: Text('개인정보 처리방침',
            style: TextStyle(
                color: style.textMuted, decoration: TextDecoration.underline)),
      ),
    );

String _randomNickname() {
  final r = Random();
  final c = Companion.all[r.nextInt(Companion.all.length)];
  return '${_adjectives[r.nextInt(_adjectives.length)]} ${c.name}${r.nextInt(90) + 10}';
}

class _RankingPageState extends State<RankingPage> {
  String _name = _randomNickname();
  bool _week = true;
  bool _busy = false;
  Future<List<RankRow>>? _rows;

  @override
  void initState() {
    super.initState();
    if (context.read<AppState>().rankNickname != null) {
      _rows = context.read<RankingService>().ranking(week: _week);
    }
  }

  void _load() {
    final rows = context.read<RankingService>().ranking(week: _week);
    setState(() {
      _rows = rows; // 화살표(=>)로 쓰면 Future를 반환해 setState가 에러
    });
  }

  Future<void> _join() async {
    final name = _name;
    if (_busy) return;
    final s = context.read<AppState>();
    final svc = context.read<RankingService>();
    setState(() => _busy = true);
    try {
      await svc.submit(s.rankScore, name);
      s.setRankNickname(name);
      _load();
    } catch (e) {
      debugPrint('ranking: $e');
      // 계정만 만들어지고 참여가 실패했으면 그 계정도 지운다
      svc.leave().catchError((_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 안 돼요. 잠시 뒤 다시 해 주세요.')));
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('랭킹에서 나갈까요?'),
        content: const Text('랭킹 계정과 닉네임·점수가 서버에서 모두 지워져요. 내 기록과 물방울은 그대로예요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('아니요')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('나가기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final s = context.read<AppState>();
    try {
      await context.read<RankingService>().leave();
      s.setRankNickname(null);
      setState(() {
        _rows = null;
      });
    } catch (e) {
      debugPrint('ranking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연결이 안 돼요. 잠시 뒤 다시 해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    return Scaffold(
      backgroundColor: style.cardBg,
      appBar: AppBar(
        backgroundColor: style.cardBg,
        foregroundColor: style.textStrong,
        surfaceTintColor: Colors.transparent,
        title: const Text('랭킹',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: MaxWidth(
            child: s.rankNickname == null ? _intro(style) : _board(style)),
      ),
    );
  }

  Widget _intro(SceneStyle style) {
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: MobileSize.cardGap),
          child: Row(children: [
            Icon(icon, size: 20, color: style.accent),
            const SizedBox(width: MobileSize.iconGap),
            Expanded(
                child: Text(text,
                    style: TextStyle(fontSize: 15, color: style.textStrong))),
          ]),
        );
    return ListView(
      padding: const EdgeInsets.all(MobileSize.gutter),
      children: [
        Text('다른 사람들과 집중을 겨뤄 볼까요?',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: style.textStrong)),
        const SizedBox(height: MobileSize.sectionGap),
        line(Icons.water_drop_outlined, '점수 = 모은 물방울 − 비상 탈출에 쓴 물방울'),
        line(Icons.storefront_outlined, '상점에서 쓴 물방울은 점수에서 빠지지 않아요'),
        line(Icons.schedule_rounded, '하루 최대 12시간까지 점수에 들어가요'),
        line(Icons.person_outline_rounded, '닉네임과 점수만 올라가요. 가입은 필요 없어요'),
        line(Icons.delete_outline_rounded, '언제든 나가면 서버에서 모두 지워져요'),
        const SizedBox(height: MobileSize.sectionGap),
        Container(
          padding: const EdgeInsets.only(left: MobileSize.cardPadding),
          decoration: BoxDecoration(
              color: style.rowBg,
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(children: [
            Expanded(
              child: Text(_name,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: style.textStrong)),
            ),
            IconButton(
              tooltip: '다른 닉네임',
              icon: Icon(Icons.casino_outlined, color: style.accent),
              onPressed: () => setState(() => _name = _randomNickname()),
            ),
          ]),
        ),
        const SizedBox(height: MobileSize.cardGap),
        PillButton(
          style: style,
          width: double.infinity,
          height: MobileSize.cta,
          icon: Icons.emoji_events_outlined,
          label: _busy ? '참여하는 중…' : '참여하기',
          onTap: _join,
        ),
        const SizedBox(height: MobileSize.cardGap),
        _privacyLink(style),
      ],
    );
  }

  Widget _board(SceneStyle style) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MobileSize.gutter, 8, MobileSize.gutter, MobileSize.cardGap),
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: true, label: Text('이번 주')),
            ButtonSegment(value: false, label: Text('누적')),
          ],
          selected: {_week},
          onSelectionChanged: (v) {
            _week = v.first;
            _load();
          },
        ),
      ),
      Expanded(
        child: FutureBuilder<List<RankRow>>(
          future: _rows,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: TextButton(
                    onPressed: _load,
                    child: const Text('연결이 안 돼요. 다시 시도')),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snap.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _load();
                await _rows;
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: MobileSize.gutter),
                children: [
                  for (final r in rows) _row(style, r),
                  const SizedBox(height: MobileSize.sectionGap),
                  Center(
                    child: TextButton(
                        onPressed: _leave,
                        child: Text('랭킹에서 나가기',
                            style: TextStyle(color: style.textMuted))),
                  ),
                  _privacyLink(style),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _row(SceneStyle style, RankRow r) => Container(
        margin: const EdgeInsets.only(bottom: MobileSize.cardGap),
        padding: const EdgeInsets.symmetric(
            horizontal: MobileSize.cardPadding, vertical: 12),
        decoration: BoxDecoration(
          color: style.rowBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: r.isMe ? style.accent : Colors.transparent, width: 2),
          boxShadow: AppShadow.card(style.rowShadow),
        ),
        child: Row(children: [
          SizedBox(
            width: 40,
            child: Text('${r.rank}',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: r.rank <= 3 ? style.accent : style.textMuted)),
          ),
          Expanded(
            child: Text(r.isMe ? '${r.nickname} (나)' : r.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, color: style.textStrong)),
          ),
          Text('💧 ${r.points}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: style.textStrong)),
        ]),
      );
}
