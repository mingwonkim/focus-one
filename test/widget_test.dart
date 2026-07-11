// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/models/task.dart';

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
}
