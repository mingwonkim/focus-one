// lib/features/expanded/expanded_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../services/window_service.dart';
import '../../state/app_state.dart';
import '../mini/widgets/focus_ring.dart';
import 'widgets/blocker_settings_view.dart';
import 'widgets/inbox_list.dart';
import 'widgets/task_list.dart';

enum _PanelView { tasks, inbox, blocker }

/// 확장 패널 (시안 Expanded Panel · 400×560):
/// 헤더(타이틀+모드 뱃지) → 장면 다이얼 216 → 컨트롤(↺ ▶ ⏭) → 오늘의 작업 → 푸터 통계
class ExpandedScreen extends StatefulWidget {
  const ExpandedScreen({super.key});

  @override
  State<ExpandedScreen> createState() => _ExpandedScreenState();
}

class _ExpandedScreenState extends State<ExpandedScreen> {
  _PanelView _view = _PanelView.tasks;

  static const _durations = [5, 15, 25, 45];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final windowService = context.read<WindowService>();
    final style = state.scene.style;
    final task = state.currentTask;
    final isBreak = state.phase == FocusPhase.breakTime;

    return Container(
      width: WindowSizes.expanded.width,
      height: WindowSizes.expanded.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: style.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: style.cardBorder),
        boxShadow: AppShadow.floating(style.shadowColor),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      // 카드가 배경색을 직접 칠하므로, 내부 잉크/리스트타일용 투명 Material을 깐다
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 상단 장식 줄 (잎 덩굴 / 별 줄 / 파도 줄)
            Positioned(
              top: -14,
              left: -2,
              right: -2,
              child: SceneGarland(scene: state.scene),
            ),
            Column(
              children: [
                // ── 헤더 ──
                DragToMoveArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FocusOne',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                                color: style.heading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _SessionLabel(state: state, style: style),
                          ],
                        ),
                      ),
                      _SoundControl(state: state, style: style),
                      IconButton(
                        tooltip: '미니 위젯으로',
                        icon: Icon(Icons.unfold_less,
                            size: 18, color: style.textFaint),
                        onPressed: () => windowService.collapse(),
                      ),
                      Tooltip(
                        message: '모드 전환',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => state.setScene(state.scene.next),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 6),
                            decoration: BoxDecoration(
                              color: style.badgeBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: style.badgeBorder),
                            ),
                            child: Text(
                              style.badgeText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: style.badgeFg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── 장면 다이얼 + 컨트롤 (작업 뷰) / 소형 타이머 줄 (인박스·차단 뷰) ──
                // 인박스·차단은 내용이 많아서 다이얼을 접어 공간을 내어준다.
                if (_view == _PanelView.tasks) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    child: FocusRing(
                      progress: state.progress,
                      remainingSeconds: state.remainingSeconds,
                      scene: state.scene,
                      size: 216,
                      stroke: 8,
                      inset: 15,
                      stateLabel: state.isRunning
                          ? '집중하는 중'
                          : (isBreak ? '휴식 중' : '준비됨'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SceneGhostButton(
                          style: style,
                          icon: Icons.replay,
                          tooltip: '리셋',
                          onTap: state.stopTimer,
                        ),
                        const SizedBox(width: 14),
                        Transform.translate(
                          offset: const Offset(0, -4),
                          child: ScenePlayButton(
                            style: style,
                            size: 62,
                            icon: isBreak
                                ? Icons.skip_next
                                : (state.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow),
                            tooltip: isBreak
                                ? '휴식 건너뛰기'
                                : (state.isRunning ? '일시정지' : '집중 시작'),
                            onTap: isBreak
                                ? state.skipBreak
                                : (task == null
                                    ? null
                                    : () => state.isRunning
                                        ? state.pauseTimer()
                                        : state.startTimer()),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SceneGhostButton(
                          style: style,
                          icon: Icons.check,
                          tooltip: '완료',
                          onTap:
                              task == null ? null : state.completeCurrentTask,
                        ),
                      ],
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 14),
                    child: _CompactTimerStrip(state: state, style: style),
                  ),

                // ── 오늘의 작업 / 인박스 / 차단 ──
                _SectionHeader(
                  style: style,
                  view: _view,
                  inboxCount: state.inbox.length,
                  onSelect: (v) => setState(() => _view = v),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: switch (_view) {
                    _PanelView.tasks => const TaskList(),
                    _PanelView.inbox => const InboxList(),
                    _PanelView.blocker => const BlockerSettingsView(),
                  },
                ),

                // ── 푸터 통계 ──
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: style.divider)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        style.footerLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: style.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${style.footerEmoji * state.todaySessionCount.clamp(0, 8)}'
                        ' ${state.todaySessionCount}${style.footerUnit}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 앰비언트 사운드 컨트롤: 아이콘 탭 → on/off 토글 + 볼륨 슬라이더 팝업
class _SoundControl extends StatelessWidget {
  const _SoundControl({required this.state, required this.style});

  final AppState state;
  final SceneStyle style;

  @override
  Widget build(BuildContext context) {
    // 기본 PopupMenuButton은 헤더 Row를 키운다 — IconButton과 같은 48px로 고정
    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<void>(
        tooltip: '사운드 설정',
        position: PopupMenuPosition.under,
        icon: Icon(
          state.soundEnabled ? Icons.volume_up : Icons.volume_off,
          size: 18,
          color: style.textFaint,
        ),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            // 팝업 안에서도 상태 변화가 바로 보이게 Consumer로 구독
            child: Consumer<AppState>(
              builder: (_, s, __) => SizedBox(
                width: 220,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: s.soundEnabled ? '소리 끄기' : '소리 켜기',
                      icon: Icon(
                        s.soundEnabled ? Icons.volume_up : Icons.volume_off,
                        size: 20,
                        color: s.soundEnabled ? style.badgeFg : style.textFaint,
                      ),
                      onPressed: () => s.setSoundEnabled(!s.soundEnabled),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: style.badgeFg,
                          inactiveTrackColor: style.ringTrack,
                          thumbColor: style.badgeFg,
                          overlayColor: style.badgeBg,
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: s.soundVolume,
                          onChanged: s.soundEnabled
                              ? (v) => s.setSoundVolume(v, persist: false)
                              : null,
                          onChangeEnd: (v) => s.setSoundVolume(v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 인박스·차단 뷰용 소형 타이머 줄: 작은 다이얼 + 시간 + 재생 버튼.
/// 큰 다이얼을 접어도 타이머 확인·조작은 계속 가능하게.
class _CompactTimerStrip extends StatelessWidget {
  const _CompactTimerStrip({required this.state, required this.style});

  final AppState state;
  final SceneStyle style;

  @override
  Widget build(BuildContext context) {
    final task = state.currentTask;
    final isBreak = state.phase == FocusPhase.breakTime;
    final m = state.remainingSeconds ~/ 60;
    final s = state.remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: style.rowBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.rowBorder),
      ),
      child: Row(
        children: [
          FocusRing(
            progress: state.progress,
            remainingSeconds: state.remainingSeconds,
            scene: state.scene,
            size: 40,
            stroke: 4,
            inset: 4,
            showLabel: false,
          ),
          const SizedBox(width: 12),
          Text(
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: style.textStrong,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.isRunning ? '집중하는 중' : (isBreak ? '휴식 중' : '준비됨'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: style.textMuted,
              ),
            ),
          ),
          ScenePlayButton(
            style: style,
            size: 34,
            icon: isBreak
                ? Icons.skip_next
                : (state.isRunning ? Icons.pause : Icons.play_arrow),
            tooltip: isBreak ? '휴식 건너뛰기' : (state.isRunning ? '일시정지' : '집중 시작'),
            onTap: isBreak
                ? state.skipBreak
                : (task == null
                    ? null
                    : () => state.isRunning
                        ? state.pauseTimer()
                        : state.startTimer()),
          ),
        ],
      ),
    );
  }
}

/// "집중 세션 · 25분" — 탭하면 길이 선택 메뉴 (타이머 정지 중에만)
class _SessionLabel extends StatelessWidget {
  const _SessionLabel({required this.state, required this.style});

  final AppState state;
  final SceneStyle style;

  @override
  Widget build(BuildContext context) {
    final isBreak = state.phase == FocusPhase.breakTime;
    final minutes = state.totalSeconds ~/ 60;
    final label = isBreak ? '휴식 · $minutes분' : '집중 세션 · $minutes분';
    final canEdit = !state.isRunning && !isBreak;

    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: style.textMuted,
      ),
    );
    if (!canEdit) return text;

    return PopupMenuButton<int>(
      tooltip: '세션 길이 변경',
      position: PopupMenuPosition.under,
      onSelected: state.setDurationMinutes,
      itemBuilder: (_) => _ExpandedScreenState._durations
          .map((m) => PopupMenuItem(value: m, child: Text('$m분')))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: text),
          Icon(Icons.arrow_drop_down, size: 14, color: style.textFaint),
        ],
      ),
    );
  }
}

/// 섹션 헤더: "오늘의 작업" + 인박스/차단 전환 (시안 라벨 스타일)
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.style,
    required this.view,
    required this.inboxCount,
    required this.onSelect,
  });

  final SceneStyle style;
  final _PanelView view;
  final int inboxCount;
  final void Function(_PanelView) onSelect;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, _PanelView v) {
      final selected = view == v;
      return InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => onSelect(v),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2, // 0.1em
              color: selected ? style.badgeFg : style.textFaint,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        // 좌우 -8: 텍스트 정렬은 유지하면서 터치 영역만 넓힌다
        Transform.translate(
          offset: const Offset(-8, 0),
          child: item('오늘의 작업', _PanelView.tasks),
        ),
        const Spacer(),
        item('인박스 $inboxCount', _PanelView.inbox),
        const SizedBox(width: 2),
        Transform.translate(
          offset: const Offset(8, 0),
          child: item('차단', _PanelView.blocker),
        ),
      ],
    );
  }
}
