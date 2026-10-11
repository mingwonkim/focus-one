// lib/mobile/mobile_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/design_tokens.dart';
import '../state/app_state.dart';
import 'lock_test_panel.dart';

enum MobileTab { focus, scenery, records, tasks }

/// 폰 셸: 탭 4개 + 떠 있는 캡슐 탭바. 화면은 P4부터 채운다.
class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  MobileTab _tab = MobileTab.focus;

  static const _labels = {
    MobileTab.focus: ('집중', Icons.timer_outlined),
    MobileTab.scenery: ('풍경', Icons.park_outlined),
    MobileTab.records: ('기록', Icons.bar_chart_rounded),
    MobileTab.tasks: ('할 일', Icons.check_circle_outline),
  };

  @override
  Widget build(BuildContext context) {
    final style = context.watch<AppState>().scene.style;
    return Scaffold(
      backgroundColor: style.cardBg,
      body: SafeArea(
        child: _tab == MobileTab.focus
            ? const LockTestPanel() // P1 시험용 — P4에서 집중 홈으로 교체
            : Center(
                child: Text(
                  _labels[_tab]!.$1,
                  style: TextStyle(fontSize: 20, color: style.textStrong),
                ),
              ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
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
                      onTap: () => setState(() => _tab = t),
                      child: Container(
                        decoration: BoxDecoration(
                          color: t == _tab ? style.divider : null,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_labels[t]!.$2,
                                size: 22,
                                color: t == _tab ? style.accent : style.textMuted),
                            Text(
                              _labels[t]!.$1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    t == _tab ? FontWeight.w600 : FontWeight.w400,
                                color: t == _tab ? style.textStrong : style.textMuted,
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
