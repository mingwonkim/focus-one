// lib/features/expanded/widgets/task_list.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_tokens.dart';
import '../../../core/scene_decorations.dart';
import '../../../models/task.dart';
import '../../../state/app_state.dart';

/// 시안의 작업 리스트: [장면 불릿] + 제목 + 🍅 세션 수.
/// 오늘 완료한 작업은 하단에 취소선으로 표시.
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
    final style = state.scene.style;
    final pending = state.pendingTasks;
    final done = state.todayDoneTasks;

    return Column(
      children: [
        Expanded(
          child: pending.isEmpty && done.isEmpty
              ? Center(
                  child: Text(
                    '할 일이 비어 있어요.\n딱 하나만 적어보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: style.textMuted),
                  ),
                )
              : ListView(
                  children: [
                    for (final task in pending)
                      _TaskRow(task: task, state: state, style: style),
                    for (final task in done)
                      _TaskRow(
                          task: task, state: state, style: style, done: true),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onSubmitted: (_) => _submit(state),
          style: TextStyle(fontSize: 14, color: style.rowText),
          decoration: InputDecoration(
            hintText: '할 일 추가 후 Enter',
            hintStyle: TextStyle(fontSize: 13, color: style.textFaint),
            filled: true,
            fillColor: style.fieldFill,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, size: 18, color: style.textMuted),
              onPressed: () => _submit(state),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.state,
    required this.style,
    this.done = false,
  });

  final Task task;
  final AppState state;
  final SceneStyle style;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final selected = !done && state.currentTask?.id == task.id;
    final pomos = state.sessionCountFor(task.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: done ? null : () => state.selectTask(task.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? style.rowSelBg : style.rowBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: selected ? style.rowSelBorder : style.rowBorder),
          ),
          child: Row(
            children: [
              SceneBullet(scene: state.scene, selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: done ? style.rowDone : style.rowText,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: style.rowDone,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '🍅 $pomos',
                style: TextStyle(fontSize: 11, color: style.textFaint),
              ),
              if (!done) ...[
                const SizedBox(width: 4),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => state.deleteTask(task.id),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 13, color: style.textFaint),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
