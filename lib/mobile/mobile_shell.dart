// lib/mobile/mobile_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../state/app_state.dart';
import 'focus/focus_home.dart';
import 'records/records_tab.dart';
import 'scenery/scenery_tab.dart';
import 'tasks/tasks_tab.dart';

enum MobileTab { focus, scenery, records, tasks }

/// 폰 셸: 탭 4개 + 떠 있는 캡슐 탭바. 화면은 P4부터 채운다.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  /// 다른 탭에서 "바로 집중" 등으로 탭을 바꿀 수 있게 Provider로 내려준다
  final _tabs = ValueNotifier(MobileTab.focus);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static const _labels = {
    MobileTab.focus: ('집중', Icons.timer_outlined),
    MobileTab.scenery: ('풍경', Icons.park_outlined),
    MobileTab.records: ('기록', Icons.bar_chart_rounded),
    MobileTab.tasks: ('할 일', Icons.check_circle_outline),
  };

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _tabs,
        child: Builder(builder: _build),
      );

  Widget _build(BuildContext context) {
    final state = context.watch<AppState>();
    final style = state.scene.style;
    // 진행·휴식 중엔 탭바를 숨긴다 (집중 화면에서 다른 데로 새지 않게)
    final hideBar = state.phase != FocusPhase.idle;
    final tab = context.watch<ValueNotifier<MobileTab>>().value;
    final current = hideBar ? MobileTab.focus : tab;
    return Scaffold(
      backgroundColor: style.cardBg,
      body: SafeArea(
        // 탭 전환 페이드 120ms (동작 줄이기면 즉시)
        child: AnimatedSwitcher(
          duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
              ? Duration.zero
              : AppDuration.tab,
          switchInCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey(current),
            child: switch (current) {
              MobileTab.focus => const FocusHome(),
              MobileTab.tasks => const TasksTab(),
              MobileTab.records => const RecordsTab(),
              MobileTab.scenery => const SceneryTab(),
            },
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: hideBar
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: style.rowBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: AppShadow.card(style.rowShadow),
                  ),
                  child: Row(
                    children: [
                      for (final t in MobileTab.values)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tabs.value = t,
                            child: Container(
                              decoration: BoxDecoration(
                                color: t == current ? style.divider : null,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_labels[t]!.$2,
                                      size: 22,
                                      color: t == current
                                          ? style.accent
                                          : style.textMuted),
                                  Text(
                                    _labels[t]!.$1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: t == current
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: t == current
                                          ? style.textStrong
                                          : style.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
