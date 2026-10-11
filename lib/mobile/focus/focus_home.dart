// lib/mobile/focus/focus_home.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../models/collection.dart';
import '../../features/mini/widgets/focus_ring.dart' show formatClock;
import '../../state/app_state.dart';
import '../lock_test_panel.dart';
import 'mobile_ring.dart';
import 'sheets.dart';

/// 집중 홈 (docs/mobile/app-design-spec.md §2):
/// 지금 할 일 카드 → 도구 행(장면·소리·잠금) → 링 → 시간 → 친구·태그 → 시작 + 메모
class FocusHome extends StatefulWidget {
  const FocusHome({super.key});

  @override
  State<FocusHome> createState() => _FocusHomeState();
}

class _FocusHomeState extends State<FocusHome> {
  int _minutes = 25;
  bool _rewardShown = false;

  void _setMinutes(AppState s, int m) {
    if (m == _minutes) return;
    ringHaptic();
    setState(() => _minutes = m);
    s.setDurationMinutes(m);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    final active = s.activeSession;
    final idle = active == null && s.phase != FocusPhase.breakTime;
    final h = MediaQuery.sizeOf(context).height;
    final ringSize = h < 700 ? 184.0 : (h > 900 ? 264.0 : MobileSize.ring);
    _minutes = idle ? s.totalSeconds ~/ 60 : _minutes;

    // 완료 직후 보상 시트 1회
    if (s.lastReward != null && !_rewardShown) {
      _rewardShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showRewardSheet(context);
        _rewardShown = false;
      });
    }

    // 진행 중엔 세션에 고정된 친구
    final companion =
        Companion.byId(active?.companionId) ?? s.selectedCompanion;
    final progress = idle ? MobileRing.fractionOf(_minutes) : s.progress;
    // 대기: 데려올 친구를 또렷하게 보여 주고, 시작하면 흐려졌다가 집중할수록 선명해짐
    final reveal = idle ? 1.0 : 0.25 + 0.75 * (1 - s.progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MobileSize.gutter),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _TaskCard(state: s, enabled: idle),
          const SizedBox(height: 8),
          if (idle) _ToolRow(state: s) else _RunningBadge(state: s),
          const Spacer(),
          MobileRing(
            scene: s.scene,
            companion: companion,
            progress: progress,
            reveal: reveal,
            size: ringSize,
            onMinutes: idle ? (m) => _setMinutes(s, m) : null,
          ),
          const SizedBox(height: 8),
          Text(
            formatClock(idle ? _minutes * 60 : s.remainingSeconds),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w600,
              height: 64 / 56,
              color: style.textStrong,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          if (idle)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _Chip(
                  state: s,
                  label: companion.name,
                  onTap: () => showCompanionSheet(context)),
              const SizedBox(width: 8),
              _Chip(
                  state: s,
                  dot: tagColor(style, s.currentTag?.colorIndex ?? 0),
                  label: s.currentTask?.tagId != null
                      ? (s.tags
                              .where((t) => t.id == s.currentTask!.tagId)
                              .firstOrNull
                              ?.name ??
                          '태그')
                      : (s.currentTag?.name ?? '태그'),
                  onTap: () => showTagSheet(context)),
            ])
          else
            SizedBox(
              height: MobileSize.row,
              child: Center(
                child: Text(
                  s.phase == FocusPhase.breakTime
                      ? '잠깐 쉬어가요'
                      : (s.isRunning
                          ? '집중할수록 ${companion.name}이(가) 선명해져요'
                          : '잠시 멈춤'),
                  style: TextStyle(fontSize: 13, color: style.textMuted),
                ),
              ),
            ),
          const Spacer(),
          _Controls(state: s),
          // 탭바 자리 (진행 중엔 탭바 숨김)
          SizedBox(height: idle ? MobileSize.tabBar + (h < 700 ? 12 : 24) : 24),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.state, required this.enabled});
  final AppState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final style = state.scene.style;
    final title = state.currentTask?.title ?? state.activeSession?.taskTitle;
    return PressScale(
      onTap: enabled ? () => showTaskSheet(context) : null,
      child: Opacity(
        opacity: 1,
        child: Container(
          height: MobileSize.taskCard,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: style.rowBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.card(style.rowShadow),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('지금 할 일',
                      style: TextStyle(fontSize: 13, color: style.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    (title == null || title.isEmpty) ? '하나만 골라볼까요?' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: style.textStrong),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right_rounded, color: style.textMuted),
          ]),
        ),
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final style = s.scene.style;
    return SizedBox(
      height: MobileSize.row,
      child: Row(children: [
        _Chip(
          state: s,
          leading: SceneBullet(scene: s.scene, selected: true),
          label: style.sceneLabel,
          onTap: () => s.setScene(s.scene.next),
        ),
        const Spacer(),
        RoundIconButton(
          style: style,
          icon: s.soundEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          tooltip: s.soundEnabled ? '소리 끄기' : '소리 켜기',
          onTap: () => s.setSoundEnabled(!s.soundEnabled),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          style: style,
          icon: Icons.lock_outline_rounded,
          tooltip: '앱 잠금',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('앱 잠금')),
                  body: const LockTestPanel()))),
        ),
      ]),
    );
  }
}

class _RunningBadge extends StatelessWidget {
  const _RunningBadge({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final style = state.scene.style;
    return SizedBox(
      height: MobileSize.row,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _Chip(
          state: state,
          dot: style.ringProgress,
          label: state.phase == FocusPhase.breakTime
              ? '휴식 중'
              : (state.isRunning ? '집중 중' : '일시정지'),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.state,
      required this.label,
      this.leading,
      this.dot,
      this.onTap});
  final AppState state;
  final String label;
  final Widget? leading;
  final Color? dot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = state.scene.style;
    final chip = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: style.rowBg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadow.card(style.rowShadow),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        if (dot != null) ...[
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: style.textStrong)),
        if (onTap != null && leading == null) ...[
          const SizedBox(width: 2),
          Icon(Icons.expand_more_rounded, size: 18, color: style.textMuted),
        ],
      ]),
    );
    return onTap == null ? chip : PressScale(onTap: onTap, child: chip);
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});
  final AppState state;

  Future<void> _confirmAbandon(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('여기서 그만둘까요?'),
        content: const Text('집중한 시간은 기록되지만 친구는 오지 않아요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('계속하기')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('그만두기')),
        ],
      ),
    );
    if (ok == true) state.abandonSession();
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    final style = s.scene.style;
    final memo = RoundIconButton(
      style: style,
      size: MobileSize.cta,
      icon: Icons.edit_note_rounded,
      tooltip: '딴생각 메모',
      onTap: () => showMemoSheet(context),
    );
    if (s.phase == FocusPhase.breakTime) {
      return Row(children: [
        Expanded(
          child: PillButton(
              style: style,
              width: double.infinity,
              height: MobileSize.cta,
              icon: Icons.skip_next_rounded,
              label: '휴식 건너뛰기',
              onTap: s.skipBreak),
        ),
      ]);
    }
    if (s.activeSession == null) {
      return Row(children: [
        Expanded(
          child: PillButton(
            style: style,
            width: double.infinity,
            height: MobileSize.cta,
            icon: Icons.play_arrow_rounded,
            label: '시작',
            onTap: () => s.startTimer(allowNoTask: true),
          ),
        ),
        const SizedBox(width: 12),
        memo,
      ]);
    }
    return Row(children: [
      RoundIconButton(
        style: style,
        size: MobileSize.cta,
        icon: Icons.stop_rounded,
        tooltip: '그만두기',
        onTap: () => _confirmAbandon(context),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: PillButton(
          style: style,
          width: double.infinity,
          height: MobileSize.cta,
          icon: s.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: s.isRunning ? '일시정지' : '계속',
          onTap: s.isRunning
              ? s.pauseTimer
              : () => s.startTimer(allowNoTask: true),
        ),
      ),
      const SizedBox(width: 12),
      memo,
    ]);
  }
}
