// lib/mobile/focus/stat_bar.dart
// 상단 스탯: 연속일 / 물방울 / 오늘 집중 분. 목표는 2단계에서 붙는다.
import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../state/app_state.dart';

class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final style = state.scene.style;
    Widget item(IconData icon, Color color, String value, String label) =>
        Semantics(
          label: '$label $value',
          excludeSemantics: true,
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
        );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: MobileSize.statBar),
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: MobileSize.cardGap,
        spacing: MobileSize.sectionGap,
        children: [
          item(Icons.local_fire_department_rounded, AppColors.flame,
              '${state.streakDays}', '연속 집중일'),
          item(Icons.water_drop_rounded, AppColors.drop, '${state.drops}', '물방울'),
          item(Icons.timer_rounded, style.accent, '${state.todayFocusMinutes}분',
              '오늘 집중'),
        ],
      ),
    );
  }
}
