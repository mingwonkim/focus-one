// lib/features/expanded/widgets/inbox_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';

/// 브레인덤프 인박스.
/// 여기 있는 항목은 "아직 할 일이 아님". 사용자가 승격해야만 할 일이 된다.
class InboxList extends StatelessWidget {
  const InboxList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    if (state.inbox.isEmpty) {
      return Center(
        child: Text(
          '작업 중 떠오른 생각은\nCtrl+Shift+Space로 여기에 쌓여요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      itemCount: state.inbox.length,
      itemBuilder: (context, index) {
        final item = state.inbox[index];
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.bolt, size: 20, color: scheme.onSurfaceVariant),
          title: Text(
            item.text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '할 일로 올리기',
                icon: Icon(Icons.arrow_upward,
                    size: 16, color: scheme.primary),
                onPressed: () => state.promoteInboxItem(item.id),
              ),
              IconButton(
                tooltip: '버리기',
                icon: Icon(Icons.close,
                    size: 16, color: scheme.onSurfaceVariant),
                onPressed: () => state.deleteInboxItem(item.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
