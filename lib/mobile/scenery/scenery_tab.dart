// lib/mobile/scenery/scenery_tab.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../models/collection.dart';
import '../../state/app_state.dart';
import 'collection_pages.dart';

/// 풍경 탭 (spec §2): 헤더(장면·물방울) → 정사각 풍경 → 편집 / 보관함·도감·상점.
/// 편집: 아래 재고에서 하나 고르고 빈 칸을 탭해 놓기, 놓인 것을 탭하면 회수. 완료=저장, 취소=원복.
class SceneryTab extends StatefulWidget {
  const SceneryTab({super.key});

  @override
  State<SceneryTab> createState() => _SceneryTabState();
}

class _SceneryTabState extends State<SceneryTab> {
  FocusScene? _viewing; // 보고 있는 풍경 (기본: 지금 장면)
  List<Placement>? _draft; // 편집 중 사본 (null = 보기)
  String? _picked; // 놓을 아이템
  bool _decorTab = false;

  void _tapCell(AppState s, FocusScene scene, int x, int y) {
    final draft = _draft!;
    final i = draft.indexWhere((p) => p.x == x && p.y == y);
    setState(() {
      if (i >= 0) {
        draft.removeAt(i); // 회수
        HapticFeedback.selectionClick();
      } else if (_picked != null && _left(s, scene, _picked!) > 0) {
        draft.add(Placement(_picked!, x, y));
        HapticFeedback.lightImpact();
        if (_left(s, scene, _picked!) == 0) _picked = null;
      }
    });
  }

  /// 편집 사본 기준 남은 수 = 보유 − (다른 장면 배치 + 사본 배치)
  int _left(AppState s, FocusScene scene, String id) {
    final elsewhere = FocusScene.values
        .where((x) => x != scene)
        .expand(s.placementsOf)
        .where((p) => p.itemId == id)
        .length;
    final here =
        (_draft ?? s.placementsOf(scene)).where((p) => p.itemId == id).length;
    return s.ownedCount(id) - elsewhere - here;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final scene = _viewing ?? s.scene;
    final style = scene.style;
    final editing = _draft != null;
    final placed = _draft ?? s.placementsOf(scene);
    final items = _decorTab
        ? Decor.all.where((d) => d.scene == scene).map((d) => (d.id, d.name))
        : Companion.of(scene).map((c) => (c.id, c.name));
    final stock = [
      for (final (id, name) in items)
        if (s.ownedCount(id) > 0) (id, name)
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MobileSize.gutter, 8, MobileSize.gutter, MobileSize.contentBottomGap),
      children: [
        Row(children: [
          Text('풍경',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: style.textStrong)),
          const Spacer(),
          if (!editing)
            _Pill(
              style: style,
              onTap: () => setState(() => _viewing = scene.next),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SceneBullet(scene: scene, selected: true),
                const SizedBox(width: 6),
                Text(scene.style.sceneLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: style.textStrong)),
              ]),
            ),
          const SizedBox(width: 8),
          _Pill(
            style: style,
            child: Text('💧 ${s.drops}',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: style.textStrong)),
          ),
        ]),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(builder: (_, box) {
            final cell = box.maxWidth / Placement.grid;
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Stack(children: [
                Positioned.fill(
                    child: CustomPaint(
                        painter: _GroundPainter(scene, grid: editing))),
                if (placed.isEmpty && !editing)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        '집중을 끝내면 친구가 와요.\n꾸미기를 눌러 이곳에 데려다 두세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, height: 1.5, color: style.textMuted),
                      ),
                    ),
                  ),
                // 위쪽 줄부터 그려 아래 줄이 앞에 오게
                for (final p in [...placed]..sort((a, b) => a.y.compareTo(b.y)))
                  Positioned(
                    left: p.x * cell - cell * 0.1,
                    top: p.y * cell - cell * 0.25,
                    width: cell * 1.2,
                    height: cell * 1.2,
                    child: IgnorePointer(
                        child: Image.asset(itemAsset(p.itemId),
                            fit: BoxFit.contain)),
                  ),
                if (editing)
                  for (var y = 0; y < Placement.grid; y++)
                    for (var x = 0; x < Placement.grid; x++)
                      Positioned(
                        left: x * cell,
                        top: y * cell,
                        width: cell,
                        height: cell,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _tapCell(s, scene, x, y),
                        ),
                      ),
              ]),
            );
          }),
        ),
        const SizedBox(height: MobileSize.sectionGap),
        if (!editing) ...[
          PillButton(
            style: style,
            width: double.infinity,
            height: MobileSize.cta,
            icon: Icons.edit_rounded,
            label: '꾸미기',
            onTap: () => setState(() {
              _draft = List.of(s.placementsOf(scene));
              _picked = null;
            }),
          ),
          const SizedBox(height: MobileSize.cardGap),
          Row(children: [
            for (final (label, icon, page) in [
              ('보관함', Icons.inventory_2_outlined, const StoragePage()),
              ('도감', Icons.menu_book_outlined, const DexPage()),
              ('상점', Icons.storefront_outlined, const ShopPage()),
            ]) ...[
              Expanded(
                child: _Pill(
                  style: style,
                  height: MobileSize.cta,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => page)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 20, color: style.textStrong),
                        const SizedBox(width: MobileSize.iconGap),
                        Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: style.textStrong)),
                      ]),
                ),
              ),
              if (label != '상점') const SizedBox(width: 8),
            ],
          ]),
        ] else ...[
          Row(children: [
            Expanded(
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('친구')),
                  ButtonSegment(value: true, label: Text('장식')),
                ],
                selected: {_decorTab},
                onSelectionChanged: (v) => setState(() => _decorTab = v.first),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _picked == null
                ? '놓을 것을 고르고 빈 칸을 누르세요. 놓인 것을 누르면 돌아와요.'
                : '빈 칸을 눌러 놓기',
            style: TextStyle(fontSize: 13, color: style.textMuted),
          ),
          const SizedBox(height: 8),
          if (stock.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _decorTab ? '상점에서 물방울로 장식을 살 수 있어요.' : '이 풍경의 친구를 아직 못 만났어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: style.textMuted),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (final (id, name) in stock)
                  _StockCard(
                    style: style,
                    id: id,
                    name: name,
                    left: _left(s, scene, id),
                    picked: _picked == id,
                    onTap: _left(s, scene, id) > 0
                        ? () =>
                            setState(() => _picked = _picked == id ? null : id)
                        : null,
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _Pill(
                style: style,
                height: MobileSize.cta,
                onTap: () => setState(() => _draft = null),
                child: Center(
                  child: Text('취소',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: style.textStrong)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PillButton(
                style: style,
                width: double.infinity,
                height: MobileSize.cta,
                icon: Icons.check_rounded,
                label: '완료',
                onTap: () {
                  s.setPlacements(scene, _draft!);
                  setState(() => _draft = null);
                },
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.style, required this.child, this.onTap, this.height = 40});
  final SceneStyle style;
  final Widget child;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      constraints: BoxConstraints(minHeight: math.max(height, MobileSize.row)),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: style.rowBg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadow.card(style.rowShadow),
      ),
      child: Center(widthFactor: 1, child: child),
    );
    return onTap == null ? box : PressScale(onTap: onTap, child: box);
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.style,
    required this.id,
    required this.name,
    required this.left,
    required this.picked,
    this.onTap,
  });
  final SceneStyle style;
  final String id, name;
  final int left;
  final bool picked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: picked,
      label: '$name $left개 남음',
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: style.rowBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: picked ? style.accent : Colors.transparent, width: 2),
          ),
          child: Column(children: [
            Expanded(child: Image.asset(itemAsset(id))),
            Text('$name ×$left',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: style.textStrong)),
          ]),
        ),
      ),
    );
  }
}

/// 장면별 바닥 (코드로 그림): 숲=풀밭, 밤=별 내린 들판, 바다=물속 모래밭. 편집 중엔 격자.
class _GroundPainter extends CustomPainter {
  _GroundPainter(this.scene, {required this.grid});
  final FocusScene scene;
  final bool grid;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final (top, bottom, speck) = switch (scene) {
      FocusScene.forest => (
          const Color(0xFFDDF2E5),
          const Color(0xFFA9DBB8),
          const Color(0xFF8CCB9E)
        ),
      FocusScene.night => (
          const Color(0xFF232C4A),
          const Color(0xFF151B30),
          const Color(0xFFE3C77F)
        ),
      FocusScene.ocean => (
          const Color(0xFFC9E9F8),
          const Color(0xFF8CC8E6),
          const Color(0xFFFFFFFF)
        ),
      FocusScene.daily => (
          const Color(0xFFFFEDE6),
          const Color(0xFFF7C7B5),
          const Color(0xFFE59478)
        ),
    };
    canvas.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ).createShader(r));
    // 고정 시드 점 무늬 (풀잎·별·물방울 느낌)
    final rnd = math.Random(scene.index + 7);
    final p = Paint()
      ..color = speck.withValues(alpha: scene == FocusScene.night ? 0.8 : 0.5);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
          Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
          1 + rnd.nextDouble() * 2,
          p);
    }
    if (grid) {
      final g = Paint()
        ..color = scene.style.textMuted.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      final c = size.width / Placement.grid;
      for (var i = 1; i < Placement.grid; i++) {
        canvas.drawLine(Offset(i * c, 0), Offset(i * c, size.height), g);
        canvas.drawLine(Offset(0, i * c), Offset(size.width, i * c), g);
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter o) => o.scene != scene || o.grid != grid;
}
