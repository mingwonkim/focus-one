// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/task.dart';
import 'package:focus_one/state/app_state.dart';

void main() {
  test('Task JSON 직렬화 왕복', () {
    final task = Task(
      id: '1',
      title: '테스트 작업',
      createdAt: DateTime(2026, 7, 11),
    );
    final restored = Task.fromJson(task.toJson());
    expect(restored.id, task.id);
    expect(restored.title, task.title);
    expect(restored.isDone, false);
  });

  test('비선택 작업 체크 완료는 타이머·현재 작업을 보존', () {
    final state = AppState(LocalStore());
    state.addTask('지금 하는 일', setAsCurrent: true);
    state.addTask('다른 일');
    final current = state.currentTask!;
    final other = state.pendingTasks.firstWhere((t) => t.id != current.id);
    state.startTimer();

    state.completeTask(other.id);

    expect(state.isRunning, isTrue);
    expect(state.currentTask?.id, current.id);
    expect(state.todayDoneTasks.map((t) => t.id), [other.id]);
    state.dispose();
  });
}
