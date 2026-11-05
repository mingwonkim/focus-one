// lib/mobile/focus/stat_bar.dart
// 상단 스탯: 연속일 / 물방울 / 오늘 집중·목표. 누르면 연속일·목표 화면으로.
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../growth/growth_pages.dart';

class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final style = state.scene.style;
    Widget item(IconData icon, Color color, String value, String label,
            {Widget? page}) =>
        Semantics(
          button: page != null,
          label: '$label $value',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: page == null
                ? null
                : () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => page)),
            child: Container(
              constraints: const BoxConstraints(minHeight: MobileSize.statBar),
              padding: const EdgeInsets.symmetric(horizontal: MobileSize.iconGap),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: MobileSize.statIcon, color: color),
                const SizedBox(width: MobileSize.labelGap),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: style.textStrong,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ]),
            ),
          ),
        );
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: MobileSize.gridGap,
        children: [
          item(Icons.local_fire_department_rounded, AppColors.flame,
              '${state.streakDays}', '연속 집중일', page: const StreakPage()),
          item(Icons.water_drop_rounded, AppColors.drop, '${state.drops}', '물방울'),
          item(Icons.timer_rounded, style.accent,
              '${state.todayMinutes}/${state.dailyGoal}분', '오늘 목표',
              page: const GoalPage()),
        ],
      ),
    );
  }
}
