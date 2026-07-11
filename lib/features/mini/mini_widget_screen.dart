// lib/features/mini/mini_widget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/design_tokens.dart';
import '../../services/window_service.dart';
import '../../state/app_state.dart';
import 'widgets/focus_ring.dart';

/// 미니 위젯: 화면 구석에 항상 떠 있는 앱의 본체.
/// 구성 = [타이머 링] + [현재 작업 1개] + [시작/일시정지] + [완료]
/// 목록·통계·설정은 전부 확장 패널로 밀어낸다.
class MiniWidgetScreen extends StatelessWidget {
  const MiniWidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final windowService = context.read<WindowService>();
    final scheme = Theme.of(context).colorScheme;
    final task = state.currentTask;

    return DragToMoveArea(
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: scheme.outline),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            FocusRing(
              progress: state.progress,
              remainingSeconds: state.remainingSeconds,
              size: 72,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task == null ? '지금 할 일을 골라주세요' : '지금 이것만',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    task?.title ?? '—',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundIconButton(
                  icon: state.isRunning ? Icons.pause : Icons.play_arrow,
                  tooltip: state.isRunning ? '일시정지' : '집중 시작',
                  isPrimary: true,
                  onTap: task == null
                      ? null
                      : () => state.isRunning
                          ? state.pauseTimer()
                          : state.startTimer(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RoundIconButton(
                  icon: Icons.unfold_more,
                  tooltip: '패널 열기',
                  onTap: () => windowService.toggleMode(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? (enabled ? scheme.primary : scheme.outline)
            : scheme.surface,
        shape: CircleBorder(
          side: isPrimary ? BorderSide.none : BorderSide(color: scheme.outline),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 18,
              color: isPrimary ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
