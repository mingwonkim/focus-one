// lib/mobile/focus/sheets.dart
// 집중 홈의 하단 시트들: 할 일 / 태그 / 친구 / 딴생각 메모 / 보상
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../models/collection.dart';
import '../../state/app_state.dart';

Future<T?> showFocusSheet<T>(
    BuildContext context, String title, WidgetBuilder body) {
  final style = context.read<AppState>().scene.style;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: style.rowBg,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(MobileSize.sheetRadius))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                    color: style.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(MobileSize.gutter, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: style.textStrong)),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    icon: Icon(Icons.close_rounded, color: style.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(child: body(ctx)),
          ],
        ),
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.child, this.selected = false, this.onTap});
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppState>().scene.style;
    return PressScale(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: style.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: selected ? style.accent : Colors.transparent, width: 2),
        ),
        child: child,
      ),
    );
  }
}

class _AddField extends StatefulWidget {
  const _AddField({required this.hint, required this.onSubmit});
  final String hint;
  final ValueChanged<String> onSubmit;

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppState>().scene.style;
    return TextField(
      controller: _c,
      onSubmitted: (v) {
        widget.onSubmit(v);
        _c.clear();
      },
      style: TextStyle(fontSize: 16, color: style.textStrong),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(Icons.add_rounded, color: style.textMuted),
        filled: true,
        fillColor: style.cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none),
      ),
    );
  }
}

/// 할 일 선택: 미완료 목록 + 추가 + 선택 없이
Future<void> showTaskSheet(BuildContext context) =>
    showFocusSheet(context, '지금 할 일', (ctx) {
      return Consumer<AppState>(builder: (_, s, __) {
        final style = s.scene.style;
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              MobileSize.gutter, 4, MobileSize.gutter, 24),
          children: [
            for (final t in s.pendingTasks)
              _Row(
                selected: s.currentTask?.id == t.id,
                onTap: () {
                  s.selectTask(t.id);
                  Navigator.pop(ctx);
                },
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, color: style.textStrong)),
                ),
              ),
            _AddField(
              hint: '할 일 추가',
              onSubmit: (v) {
                s.addTask(v, setAsCurrent: true);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                s.clearCurrentTask();
                Navigator.pop(ctx);
              },
              child: Text('할 일 없이 태그만으로 집중',
                  style: TextStyle(color: style.textMuted)),
            ),
          ],
        );
      });
    });

/// 태그 선택·추가
Future<void> showTagSheet(BuildContext context) =>
    showFocusSheet(context, '태그', (ctx) {
      return Consumer<AppState>(builder: (_, s, __) {
        final style = s.scene.style;
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              MobileSize.gutter, 4, MobileSize.gutter, 24),
          children: [
            for (final t in s.tags)
              _Row(
                selected: s.currentTag?.id == t.id,
                onTap: () {
                  s.selectTag(t.id);
                  Navigator.pop(ctx);
                },
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: tagColor(style, t.colorIndex),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Text(t.name,
                      style: TextStyle(fontSize: 16, color: style.textStrong)),
                ]),
              ),
            _AddField(hint: '새 태그', onSubmit: s.addTag),
          ],
        );
      });
    });

/// 태그 색: 장면 링 색 기준 명도 변화 (강조색 하나 원칙)
Color tagColor(SceneStyle style, int i) {
  const k = [1.0, 0.7, 0.45, 0.85, 0.6];
  return Color.lerp(style.cardBg, style.ringProgress, k[i % k.length])!;
}

/// 데려올 친구: 현재 장면 2열, 잠김은 실루엣 + 남은 분
Future<void> showCompanionSheet(BuildContext context) =>
    showFocusSheet(context, '데려올 친구', (ctx) {
      return Consumer<AppState>(builder: (_, s, __) {
        final style = s.scene.style;
        final done = s.sceneMinutes(s.scene);
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 169 / 156,
          padding: const EdgeInsets.fromLTRB(
              MobileSize.gutter, 4, MobileSize.gutter, 24),
          children: [
            for (final c in Companion.of(s.scene))
              PressScale(
                onTap: s.isUnlocked(c)
                    ? () {
                        s.selectCompanion(c.id);
                        Navigator.pop(ctx);
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: style.cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: s.selectedCompanion.id == c.id
                            ? style.accent
                            : Colors.transparent,
                        width: 2),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    Expanded(
                      child: s.isUnlocked(c)
                          ? Image.asset(c.asset)
                          : ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                  style.divider, BlendMode.srcIn),
                              child: Image.asset(c.asset)),
                    ),
                    Text(c.name,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: style.textStrong)),
                    if (!s.isUnlocked(c))
                      Text('${c.unlockMinutes - done}분 더',
                          style:
                              TextStyle(fontSize: 12, color: style.textMuted)),
                  ]),
                ),
              ),
          ],
        );
      });
    });

/// 딴생각 메모: 저장하면 바로 닫히고 타이머는 그대로
Future<void> showMemoSheet(BuildContext context) =>
    showFocusSheet(context, '딴생각 메모', (ctx) => const _MemoBody());

class _MemoBody extends StatefulWidget {
  const _MemoBody();

  @override
  State<_MemoBody> createState() => _MemoBodyState();
}

class _MemoBodyState extends State<_MemoBody> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _save() {
    if (_c.text.trim().isEmpty) return;
    context.read<AppState>().addToInbox(_c.text);
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppState>().scene.style;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MobileSize.gutter, 4, MobileSize.gutter, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _c,
          autofocus: true,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _save(),
          style: TextStyle(fontSize: 16, color: style.textStrong),
          decoration: InputDecoration(
            hintText: '떠오른 생각을 적고 다시 집중',
            filled: true,
            fillColor: style.cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 12),
        PillButton(
          style: style,
          width: double.infinity,
          height: MobileSize.cta,
          icon: Icons.check_rounded,
          label: '저장하고 돌아가기',
          onTap: _c.text.trim().isEmpty ? null : _save,
        ),
      ]),
    );
  }
}

/// 보상: 친구 팝(.85→1 easeOutBack) + 햅틱, 물방울
Future<void> showRewardSheet(BuildContext context) {
  final s = context.read<AppState>();
  final r = s.lastReward;
  if (r == null) return Future.value();
  final c = Companion.byId(r.companionId);
  final drops = (r.focusedSec ?? 0) ~/ 60;
  HapticFeedback.mediumImpact();
  return showFocusSheet(context, '집중 완료', (ctx) {
    final style = s.scene.style;
    final reduce = MediaQuery.maybeDisableAnimationsOf(ctx) ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          MobileSize.gutter, 0, MobileSize.gutter, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${r.minutes}분 동안 집중했어요',
            style: TextStyle(fontSize: 13, color: style.textMuted)),
        const SizedBox(height: 12),
        if (c != null)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? 1 : 0.85, end: 1),
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Image.asset(c.asset, width: 144, height: 144),
          ),
        if (c != null)
          Text('${c.name}이(가) 왔어요',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: style.textStrong)),
        const SizedBox(height: 12),
        Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: style.cardBg,
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Text('💧 물방울 +$drops',
              style: TextStyle(fontSize: 16, color: style.textStrong)),
        ),
        if (r.taskId.isNotEmpty &&
            s.pendingTasks.any((t) => t.id == r.taskId)) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              s.completeTask(r.taskId);
              HapticFeedback.lightImpact();
            },
            icon: Icon(Icons.check_circle_outline_rounded, color: style.accent),
            label: Text('"${r.taskTitle}" 끝냈어요',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: style.accent)),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: PillButton(
              style: style,
              width: double.infinity,
              height: MobileSize.cta,
              icon: Icons.local_cafe_rounded,
              label: '5분 휴식',
              onTap: () {
                s.startBreak();
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(width: 12),
          RoundIconButton(
            style: style,
            size: MobileSize.cta,
            icon: Icons.close_rounded,
            tooltip: '닫기',
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ]),
    );
  }).whenComplete(s.clearLastReward);
}

/// 소리: 장면 소리·빗소리·백색·갈색·끄기 + 볼륨. 즉시 적용, 다음 집중에도 기억.
Future<void> showSoundSheet(BuildContext context) =>
    showFocusSheet(context, '집중 소리', (ctx) {
      return Consumer<AppState>(builder: (_, s, __) {
        final style = s.scene.style;
        // 장면 소리(지금 장면) · 상황 소리 · 소음 — 아이디는 assets/sounds/<id>.m4a
        final groups = [
          ('장면', [('scene', '${style.sceneLabel} 소리', Icons.landscape_outlined)]),
          ('상황', [
            ('cafe', '카페', Icons.local_cafe_outlined),
            ('library', '도서관', Icons.menu_book_outlined),
            ('rain', '비 오는 날', Icons.water_drop_outlined),
            ('fire', '모닥불', Icons.local_fire_department_outlined),
            ('train', '기차 안', Icons.train_outlined),
            ('wind', '바람', Icons.air_rounded),
          ]),
          ('소음', [
            ('white', '백색소음', Icons.blur_on_rounded),
            ('brown', '갈색소음', Icons.graphic_eq_rounded),
          ]),
        ];
        Widget row(String label, IconData icon, bool selected, VoidCallback onTap) => _Row(
              selected: selected,
              onTap: onTap,
              child: Row(children: [
                Icon(icon, color: style.textStrong),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: style.textStrong))),
                if (selected) Icon(Icons.check_rounded, color: style.accent),
              ]),
            );
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
              MobileSize.gutter, 4, MobileSize.gutter, 24),
          children: [
            for (final (title, options) in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(title, style: TextStyle(fontSize: 13, color: style.textMuted)),
              ),
              for (final (id, label, icon) in options)
                row(label, icon, s.soundEnabled && s.soundId == id, () {
                  s.setSoundEnabled(true);
                  s.setSoundId(id);
                }),
            ],
            row('끄기', Icons.volume_off_outlined, !s.soundEnabled,
                () => s.setSoundEnabled(false)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.volume_down_rounded, color: style.textMuted),
              Expanded(
                child: Slider(
                  value: s.soundVolume,
                  activeColor: style.ringProgress,
                  onChanged: s.soundEnabled
                      ? (v) => s.setSoundVolume(v, persist: false)
                      : null,
                  onChangeEnd: s.setSoundVolume,
                ),
              ),
              Icon(Icons.volume_up_rounded, color: style.textMuted),
            ]),
            Text('집중하는 동안에만 들려요. 다음 집중에도 기억돼요.',
                style: TextStyle(fontSize: 12, color: style.textMuted)),
          ],
        );
      });
    });
