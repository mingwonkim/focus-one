// lib/mobile/growth/growth_tab.dart
// 성장 탭: 지도 · 퀘스트 · 리그 · 업적. 값은 전부 기록에서 계산하고, 저장되는 건 안 연 상자뿐이다.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../models/focus_title.dart';
import '../../models/growth.dart';
import '../../state/app_state.dart';
import '../focus/sheets.dart';
import '../widgets/title_avatar.dart';
import 'growth_pages.dart';
import 'league_view.dart';

enum _Section { map, quests, league, achievements }

class GrowthTab extends StatefulWidget {
  const GrowthTab({super.key});

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab> {
  _Section _section = _Section.map;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            MobileSize.gutter, 8, MobileSize.gutter, MobileSize.cardGap),
        child: SizedBox(
          width: double.infinity,
          child: SegmentedButton<_Section>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: _Section.map, label: Text('지도')),
              ButtonSegment(
                  value: _Section.quests,
                  label: Text(s.unopenedChests.isEmpty
                      ? '퀘스트'
                      : '퀘스트 ${s.unopenedChests.length}')),
              const ButtonSegment(value: _Section.league, label: Text('리그')),
              const ButtonSegment(
                  value: _Section.achievements, label: Text('업적')),
            ],
            selected: {_section},
            onSelectionChanged: (v) => setState(() => _section = v.first),
          ),
        ),
      ),
      Expanded(
        child: switch (_section) {
          _Section.map => const _MapView(),
          _Section.quests => const _QuestsView(),
          _Section.league => const LeagueView(),
          _Section.achievements => const _AchievementsView(),
        },
      ),
    ]);
  }
}

BoxDecoration _card(SceneStyle style) => BoxDecoration(
      color: style.rowBg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadow.card(style.rowShadow),
    );

// ---- 지도 ----

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final current = MapNode.currentIndex(context.read<AppState>().xp);
    _scroll = ScrollController(
        initialScrollOffset:
            math.max(0, current - 2) * MobileSize.mapRowHeight);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _describe(BuildContext context, AppState s, MapNode n) {
    final style = s.scene.style;
    final left = n.xp - s.xp;
    showFocusSheet(context, 'Lv.${n.level}', (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            MobileSize.gutter, 4, MobileSize.gutter, MobileSize.sectionGap),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (n.title != null) ...[
            TitleBadge(
                title: n.title!,
                textColor: style.textStrong,
                height: MobileSize.badgeLarge),
            const SizedBox(height: MobileSize.gridGap),
          ],
          Text(
            left <= 0 ? '이미 지나온 자리예요' : '$left분 더 집중하면 닿아요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: style.textStrong),
          ),
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    final xp = s.xp;
    final current = MapNode.currentIndex(xp);
    final title = s.title;
    final level = s.level;
    final reached = MapNode.all[level - 1];
    final next = level < MapNode.all.length ? MapNode.all[level] : null;
    final ring = TitleRings.all[title.index];
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: MobileSize.gutter),
        padding: EdgeInsets.all(ring.width),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(colors: [
            ring.colors.first,
            ring.colors.last,
          ]),
          boxShadow: AppShadow.card(style.rowShadow),
        ),
        child: Container(
        padding: const EdgeInsets.all(MobileSize.cardPadding),
        decoration: BoxDecoration(
          color: style.rowBg,
          borderRadius: BorderRadius.circular(AppRadius.lg - ring.width),
        ),
        child: Row(children: [
          TitleBadge(
              title: title,
              textColor: style.textStrong,
              height: MobileSize.badgeLarge),
          const SizedBox(width: MobileSize.gridGap),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lv.$level',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: style.textStrong)),
                  const SizedBox(height: MobileSize.labelGap),
                  _LevelBar(
                      style: style,
                      progress: next == null
                          ? 1
                          : (xp - reached.xp) / (next.xp - reached.xp)),
                  const SizedBox(height: MobileSize.labelGap),
                  Text(
                    next == null
                        ? '최고 레벨이에요'
                        : '다음 레벨까지 ${next.xp - xp}분'
                            '${title.next == null ? '' : ' · ${title.next!.label}까지 ${title.remaining(xp)}분'}',
                    style: TextStyle(fontSize: 13, color: style.textMuted),
                  ),
                ]),
          ),
        ]),
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: MobileSize.gridGap),
          itemExtent: MobileSize.mapRowHeight,
          itemCount: MapNode.all.length,
          itemBuilder: (context, i) {
            final n = MapNode.all[i];
            final prevXp = i == 0 ? 0 : MapNode.all[i - 1].xp;
            return _MapRow(
              index: i,
              node: n,
              style: style,
              done: n.xp <= xp,
              isCurrent: i == current && n.xp > xp,
              progress: (xp - prevXp) / math.max(1, n.xp - prevXp),
              companionAsset: s.selectedCompanion.asset,
              onTap: () => _describe(context, s, n),
            );
          },
        ),
      ),
    ]);
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.style, required this.progress});
  final SceneStyle style;
  final double progress;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          height: MobileSize.goalBar,
          color: style.ringTrack,
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: style.ringProgress),
          ),
        ),
      );
}

/// 칸의 좌우 위치. 가운데 오는 칭호 칸은 옆 글자가 화면을 넘지 않게 왼쪽으로 비킨다.
double _mapOffset(int i) {
  final dx = math.sin(i * math.pi / 3) * MobileSize.mapSwing;
  final titled = i < MapNode.all.length && MapNode.all[i].title != null;
  return titled && dx.abs() < 1 ? -MobileSize.mapSwing / 2 : dx;
}

class _MapRow extends StatelessWidget {
  const _MapRow({
    required this.index,
    required this.node,
    required this.style,
    required this.done,
    required this.isCurrent,
    required this.progress,
    required this.companionAsset,
    required this.onTap,
  });

  final int index;
  final MapNode node;
  final SceneStyle style;
  final bool done;
  final bool isCurrent;
  final double progress;
  final String companionAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final big = node.title != null;
    final size = big ? MobileSize.mapNodeBig : MobileSize.mapNode;
    final dx = _mapOffset(index);
    final chipSide = dx > 0 ? -1.0 : 1.0; // 화면에서 넓은 쪽
    final label = big
        ? 'Lv.${node.level}, 칭호 ${node.title!.label}'
        : 'Lv.${node.level}';
    // 칸은 자기가 속한 칭호 구간의 색을 입는다
    final zone = TitleRings.all[FocusTitle.of(node.xp).index];
    final numberColor = done
        ? zone.onFill
        : (isCurrent ? style.accent : style.textFaint);
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      Positioned.fill(
        child: CustomPaint(
          painter: _LinkPainter(
            from: dx,
            to: _mapOffset(index + 1),
            color: done ? zone.colors.first : style.ringTrack,
            last: index == MapNode.all.length - 1,
          ),
        ),
      ),
      Transform.translate(
        offset: Offset(dx, 0),
        child: Semantics(
          button: true,
          onTap: onTap,
          label: done ? '$label, 지나옴' : (isCurrent ? '$label, 지금 여기' : label),
          excludeSemantics: true,
          child: PressScale(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: isCurrent
                    ? _CurrentPainter(
                        progress: progress.clamp(0.0, 1.0),
                        track: style.ringTrack,
                        color: style.accent)
                    : null,
                child: Padding(
                  padding: EdgeInsets.all(isCurrent ? 6 : 0),
                  child: CustomPaint(
                    foregroundPainter: big
                        ? TitleFramePainter(
                            ring: zone,
                            reached: done,
                            ornamentGap: isCurrent ? 12 : 6)
                        : null,
                    child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? zone.colors.first : style.rowBg,
                      boxShadow: AppShadow.card(style.rowShadow),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(MobileSize.cardGap),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          if (big)
                            Icon(
                                zone.stars
                                    ? Icons.auto_awesome_rounded
                                    : Icons.military_tech_rounded,
                                size: size * 0.3,
                                color: done ? numberColor : zone.colors.first),
                          Text('${node.level}',
                              style: TextStyle(
                                  fontSize: big ? 34 : 24,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: numberColor)),
                        ]),
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (big)
        Transform.translate(
          offset: Offset(dx + chipSide * (size / 2 + 18), 0), // 장식과 닿지 않게
          child: FractionalTranslation(
            translation: Offset(chipSide * 0.5, 0),
            child: ExcludeSemantics(
              child: _TitleChip(
                  style: style, title: node.title!, reached: done),
            ),
          ),
        ),
      if (isCurrent)
        Transform.translate(
          // 칭호 칸이면 칭호 글자 반대쪽으로 비킨다
          offset: Offset(dx + (big ? -chipSide : chipSide) * (size / 2 + 40), 0),
          child: ExcludeSemantics(
            child: Image.asset(companionAsset,
                width: MobileSize.mapNode, height: MobileSize.mapNode),
          ),
        ),
    ]);
  }
}

/// 칭호 이름: 지도에서 가장 눈에 띄는 글자. 칭호 배지를 크게, 뒤 길이 비치지 않게 깔고 쓴다.
class _TitleChip extends StatelessWidget {
  const _TitleChip(
      {required this.style, required this.title, required this.reached});
  final SceneStyle style;
  final FocusTitle title;
  final bool reached;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: style.rowBg,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: AppShadow.card(style.rowShadow),
        ),
        child: Opacity(
          opacity: reached ? 1 : 0.72,
          child: TitleBadge(
              title: title,
              textColor: style.textStrong,
              height: MobileSize.mapTitleChip,
              weight: FontWeight.w900),
        ),
      );
}

class _LinkPainter extends CustomPainter {
  const _LinkPainter(
      {required this.from,
      required this.to,
      required this.color,
      required this.last});
  final double from;
  final double to;
  final Color color;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    if (last) return;
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx + from, size.height / 2)
      ..cubicTo(cx + from, size.height, cx + to, size.height, cx + to,
          size.height * 1.5);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = MobileSize.mapLink
          ..color = color);
  }

  @override
  bool shouldRepaint(_LinkPainter o) =>
      o.from != from || o.to != to || o.color != color || o.last != last;
}

class _CurrentPainter extends CustomPainter {
  const _CurrentPainter(
      {required this.progress, required this.track, required this.color});
  final double progress;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..color = track;
    canvas.drawCircle(c, r, p);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
        2 * math.pi * progress, false, p..color = color);
  }

  @override
  bool shouldRepaint(_CurrentPainter o) =>
      o.progress != progress || o.color != color || o.track != track;
}

// ---- 퀘스트 ----

class _QuestsView extends StatelessWidget {
  const _QuestsView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    final today = s.todayKey;
    final week = s.thisWeekKey;
    final firstKey = QuestKind.firstSession.keyFor(today);
    final dailyKey = QuestKind.dailyGoal.keyFor(today);
    final weeklyKey = QuestKind.weeklyGoal.keyFor(week);
    final older = s.unopenedChests.difference({
      firstKey,
      dailyKey,
      weeklyKey,
      QuestKind.dailyLong.keyFor(today),
      QuestKind.weeklyHalf.keyFor(week),
      QuestKind.weeklyFull.keyFor(week),
    });
    // 고정 분량 퀘스트: 내 목표와 같으면 겹치므로 숨긴다 (이미 받았으면 상자를 보여 준다)
    List<Widget> fixed(QuestKind q, String period, int done, int goal, String when) =>
        q.minutes == goal && !s.isRewarded(q.keyFor(period))
            ? const []
            : [
                const SizedBox(height: MobileSize.cardGap),
                _QuestCard(
                  style: style,
                  title: '$when ${q.minutes}분 집중하기',
                  reward: '물방울 ${q.drops}개',
                  done: done,
                  goal: q.minutes!,
                  unit: '분',
                  chestKey: q.keyFor(period),
                ),
              ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(MobileSize.gutter, 0, MobileSize.gutter,
          MobileSize.sectionGap),
      children: [
        if (older.isNotEmpty) ...[
          PillButton(
            style: style,
            width: double.infinity,
            height: MobileSize.cta,
            icon: Icons.card_giftcard_rounded,
            label: '지난 상자 ${older.length}개 열기',
            onTap: () {
              HapticFeedback.mediumImpact();
              s.openChests(older);
            },
          ),
          const SizedBox(height: MobileSize.gridGap),
        ],
        _SectionLabel(style: style, text: '오늘'),
        _QuestCard(
          style: style,
          title: '오늘 한 번 끝까지 집중하기',
          reward: '물방울 ${QuestKind.firstSession.drops}개',
          done: s.isRewarded(firstKey) ? 1 : 0,
          goal: 1,
          unit: '회',
          chestKey: firstKey,
        ),
        const SizedBox(height: MobileSize.cardGap),
        _QuestCard(
          style: style,
          title: '오늘 ${s.dailyGoal}분 집중하기',
          reward: '물방울 ${QuestKind.dailyGoal.drops}개',
          done: s.todayMinutes,
          goal: s.dailyGoal,
          unit: '분',
          chestKey: dailyKey,
        ),
        ...fixed(QuestKind.dailyLong, today, s.todayMinutes, s.dailyGoal, '오늘'),
        const SizedBox(height: MobileSize.sectionGap),
        _SectionLabel(style: style, text: '이번 주'),
        _QuestCard(
          style: style,
          title: '이번 주 ${s.weeklyGoal}분 집중하기',
          reward: '물방울 ${QuestKind.weeklyGoal.drops}개와 얼음',
          done: s.thisWeekMinutes,
          goal: s.weeklyGoal,
          unit: '분',
          chestKey: weeklyKey,
        ),
        for (final q in [QuestKind.weeklyHalf, QuestKind.weeklyFull])
          ...fixed(q, week, s.thisWeekMinutes, s.weeklyGoal, '이번 주'),
        const SizedBox(height: MobileSize.cardGap),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const GoalPage())),
            child: Text('목표 바꾸기', style: TextStyle(color: style.accent)),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.style, required this.text});
  final SceneStyle style;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: MobileSize.cardGap),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: style.textMuted)),
      );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.style,
    required this.title,
    required this.reward,
    required this.done,
    required this.goal,
    required this.unit,
    required this.chestKey,
  });

  final SceneStyle style;
  final String title;
  final String reward;
  final int done;
  final int goal;
  final String unit;
  final String chestKey;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final rewarded = s.isRewarded(chestKey);
    final unopened = s.unopenedChests.contains(chestKey);
    return Container(
      constraints: const BoxConstraints(minHeight: MobileSize.questCard),
      padding: const EdgeInsets.all(MobileSize.cardPadding),
      decoration: _card(style),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: style.textStrong)),
                const SizedBox(height: MobileSize.labelGap),
                Text(
                    rewarded
                        ? (unopened ? '달성! 상자를 눌러 열어요' : '달성 · $reward 받음')
                        : '보상 $reward',
                    style: TextStyle(
                        fontSize: 13,
                        color: rewarded ? style.accent : style.textMuted)),
                const SizedBox(height: MobileSize.cardGap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    height: MobileSize.goalBar,
                    color: style.ringTrack,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor:
                          (rewarded ? 1.0 : done / math.max(1, goal)).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: style.ringProgress),
                    ),
                  ),
                ),
                const SizedBox(height: MobileSize.labelGap),
                Text('${math.min(done, goal)} / $goal$unit',
                    style: TextStyle(fontSize: 12, color: style.textMuted)),
              ]),
        ),
        const SizedBox(width: MobileSize.gridGap),
        Semantics(
          container: true,
          button: unopened,
          onTap: unopened ? () => s.openChests([chestKey]) : null,
          label: unopened ? '상자 열기' : (rewarded ? '열린 상자' : '잠긴 상자'),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: unopened
                ? () {
                    HapticFeedback.mediumImpact();
                    s.openChests([chestKey]);
                  }
                : null,
            child: _Chest(
              style: style,
              open: rewarded && !unopened,
              dim: !rewarded,
              ready: unopened,
            ),
          ),
        ),
      ]),
    );
  }
}

/// 상자: 장면 색으로 그린다. 열릴 때 살짝 튀어 오른다.
class _Chest extends StatelessWidget {
  const _Chest(
      {required this.style,
      required this.open,
      required this.dim,
      required this.ready});
  final SceneStyle style;
  final bool open;
  final bool dim;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(clipBehavior: Clip.none, children: [
      TweenAnimationBuilder<double>(
        key: ValueKey(open),
        tween: Tween(begin: reduce ? 1 : 0.92, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: CustomPaint(
          size: const Size.square(MobileSize.chest),
          painter: _ChestPainter(
            open: open,
            body: dim ? style.ringTrack : style.ringProgress,
            lid: dim ? style.divider : style.accent,
            mark: dim ? style.textFaint : style.rowBg,
          ),
        ),
      ),
      if (ready)
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: MobileSize.chestDot,
            height: MobileSize.chestDot,
            decoration:
                BoxDecoration(color: style.accent, shape: BoxShape.circle),
          ),
        ),
    ]);
  }
}

class _ChestPainter extends CustomPainter {
  const _ChestPainter(
      {required this.open,
      required this.body,
      required this.lid,
      required this.mark});
  final bool open;
  final Color body;
  final Color lid;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width;
    final bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(u * 0.12, u * 0.42, u * 0.76, u * 0.46),
        Radius.circular(u * 0.1));
    canvas.drawRRect(bodyRect, Paint()..color = body);
    final lidPaint = Paint()..color = lid;
    if (open) {
      // 열린 뚜껑과 안의 물방울
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(u * 0.12, u * 0.12, u * 0.76, u * 0.2),
              Radius.circular(u * 0.09)),
          lidPaint);
      for (final dx in [0.34, 0.5, 0.66]) {
        _drop(canvas, Offset(u * dx, u * 0.42), u * 0.075, lidPaint);
      }
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(u * 0.08, u * 0.28, u * 0.84, u * 0.26),
              Radius.circular(u * 0.11)),
          lidPaint);
      _drop(canvas, Offset(u * 0.5, u * 0.62), u * 0.08, Paint()..color = mark);
    }
  }

  void _drop(Canvas c, Offset center, double r, Paint p) {
    c.drawCircle(center, r, p);
    c.drawPath(
        Path()
          ..moveTo(center.dx - r * 0.85, center.dy - r * 0.45)
          ..lineTo(center.dx, center.dy - r * 1.9)
          ..lineTo(center.dx + r * 0.85, center.dy - r * 0.45)
          ..close(),
        p);
  }

  @override
  bool shouldRepaint(_ChestPainter o) =>
      o.open != open || o.body != body || o.lid != lid || o.mark != mark;
}

// ---- 업적 ----

class _AchievementsView extends StatelessWidget {
  const _AchievementsView();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    return ListView(
      padding: const EdgeInsets.fromLTRB(MobileSize.gutter, 0, MobileSize.gutter,
          MobileSize.sectionGap),
      children: [
        for (final a in Achievement.values) ...[
          Container(
            padding: const EdgeInsets.all(MobileSize.cardPadding),
            decoration: _card(style),
            child: Row(children: [
              Icon(
                s.hasAchievement(a)
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
                color: s.hasAchievement(a) ? style.accent : style.textFaint,
              ),
              const SizedBox(width: MobileSize.gridGap),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: style.textStrong)),
                      Text(a.detail,
                          style:
                              TextStyle(fontSize: 13, color: style.textMuted)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: MobileSize.cardGap),
        ],
      ],
    );
  }
}
