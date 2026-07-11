// lib/features/expanded/expanded_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/design_tokens.dart';
import '../../services/window_service.dart';
import '../../state/app_state.dart';
import '../mini/widgets/focus_ring.dart';
import 'widgets/inbox_list.dart';
import 'widgets/stats_bar.dart';
import 'widgets/task_list.dart';

/// 확장 패널: 미니 위젯에서 열었을 때만 보이는 관리 화면.
/// 여기서 작업을 고르고 닫으면 다시 미니 위젯으로 돌아간다.
class ExpandedScreen extends StatelessWidget {
  const ExpandedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final windowService = context.read<WindowService>();
    final scheme = Theme.of(context).colorScheme;
    final task = state.currentTask;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          // 상단 바 (드래그 이동 + 접기)
          DragToMoveArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Text(
                    'FocusOne',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '미니 위젯으로',
                    icon: const Icon(Icons.unfold_less, size: 20),
                    onPressed: () => windowService.collapse(),
                  ),
                ],
              ),
            ),
          ),

          // 현재 작업 + 타이머 영역
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                FocusRing(
                  progress: state.progress,
                  remainingSeconds: state.remainingSeconds,
                  size: 96,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task?.title ?? '아래에서 할 일 하나를 고르세요',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DurationSelector(
                        enabled: !state.isRunning,
                        totalSeconds: state.totalSeconds,
                        onSelect: state.setDurationMinutes,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: task == null
                                ? null
                                : () => state.isRunning
                                    ? state.pauseTimer()
                                    : state.startTimer(),
                            icon: Icon(
                              state.isRunning
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 18,
                            ),
                            label: Text(state.isRunning ? '일시정지' : '시작'),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: task == null
                                ? null
                                : state.completeCurrentTask,
                            child: const Text('완료'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: scheme.outline),

          // 작업 목록 / 인박스 탭
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: scheme.primary,
                    unselectedLabelColor: scheme.onSurfaceVariant,
                    indicatorColor: scheme.primary,
                    tabs: [
                      const Tab(text: '할 일'),
                      Tab(text: '인박스 (${state.inbox.length})'),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        TaskList(),
                        InboxList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: scheme.outline),
          const StatsBar(),
        ],
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.enabled,
    required this.totalSeconds,
    required this.onSelect,
  });

  final bool enabled;
  final int totalSeconds;
  final void Function(int minutes) onSelect;

  static const _options = [5, 15, 25, 45];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs,
      children: _options.map((m) {
        final selected = totalSeconds == m * 60;
        return ChoiceChip(
          label: Text('$m분'),
          selected: selected,
          onSelected: enabled ? (_) => onSelect(m) : null,
          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
          selectedColor: scheme.primary,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
