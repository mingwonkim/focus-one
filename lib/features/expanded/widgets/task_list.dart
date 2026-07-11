// lib/features/expanded/widgets/task_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_tokens.dart';
import '../../../services/window_service.dart';
import '../../../state/app_state.dart';

class TaskList extends StatefulWidget {
  const TaskList({super.key});

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(AppState state) {
    state.addTask(_controller.text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final tasks = state.pendingTasks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onSubmitted: (_) => _submit(state),
            decoration: InputDecoration(
              hintText: '할 일 추가 후 Enter',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => _submit(state),
              ),
            ),
          ),
        ),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    '할 일이 비어 있어요.\n딱 하나만 적어보세요.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isCurrent = state.currentTask?.id == task.id;
                    return ListTile(
                      dense: true,
                      selected: isCurrent,
                      selectedTileColor:
                          scheme.primary.withValues(alpha: 0.08),
                      leading: Icon(
                        isCurrent
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: isCurrent
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        tooltip: '삭제',
                        icon: Icon(Icons.close,
                            size: 16, color: scheme.onSurfaceVariant),
                        onPressed: () => state.deleteTask(task.id),
                      ),
                      onTap: () {
                        state.selectTask(task.id);
                        // 작업을 골랐으면 바로 미니 모드로 — 목록에 머물지 않게
                        context.read<WindowService>().collapse();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
