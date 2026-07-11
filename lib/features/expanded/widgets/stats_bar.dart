// lib/features/expanded/widgets/stats_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_tokens.dart';
import '../../../state/app_state.dart';

/// 하단 통계 바. 도파민 루프의 최소 단위 — 오늘 집중 시간과 스트릭만 보여준다.
class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '오늘 ${state.todayFocusMinutes}분 집중',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Icon(Icons.local_fire_department,
              size: 16,
              color: state.streakDays > 0
                  ? scheme.primary
                  : scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${state.streakDays}일 연속',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
