// lib/features/mini/mini_widget_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/design_tokens.dart';
import '../../core/scene_decorations.dart';
import '../../services/window_service.dart';
import '../../state/app_state.dart';
import 'widgets/focus_ring.dart';

/// 미니 위젯 (시안 Mini Widget · 320×128):
/// [장면 다이얼 88] + [라벨/현재 작업] + [재생 버튼 48]
class MiniWidgetScreen extends StatelessWidget {
  const MiniWidgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final windowService = context.read<WindowService>();
    final style = state.scene.style;
    final task = state.currentTask;
    final isBreak = state.phase == FocusPhase.breakTime;

    return DragToMoveArea(
      child: Container(
        width: WindowSizes.mini.width,
        height: WindowSizes.mini.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: style.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: style.cardBorder),
          boxShadow: AppShadow.floating(style.shadowColor),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: MiniCornerAccents(scene: state.scene)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  FocusRing(
                    progress: state.progress,
                    remainingSeconds: state.remainingSeconds,
                    scene: state.scene,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isBreak ? '휴식 중 — 차단 해제됨' : '지금 집중할 일',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.66, // 0.06em
                            color: style.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBreak
                              ? '잠깐 쉬어가세요'
                              : (task?.title ?? '할 일을 골라주세요'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: style.textStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScenePlayButton(
                    style: style,
                    icon: isBreak
                        ? Icons.skip_next
                        : (state.isRunning ? Icons.pause : Icons.play_arrow),
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
                ],
              ),
            ),
            // 패널 열기 (시안엔 없지만 기능상 필요 — 우하단에 은은하게)
            Positioned(
              right: 6,
              bottom: 4,
              child: IconButton(
                tooltip: '패널 열기',
                icon: Icon(Icons.unfold_more, size: 14, color: style.textFaint),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => windowService.toggleMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

