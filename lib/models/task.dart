// lib/models/task.dart

/// 할 일. ADHD 원칙: 목록은 뒤에 숨기고, 화면에는 항상 1개만 노출한다.
class Task {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
  });

  Task copyWith({String? title, bool? isDone, DateTime? completedAt}) => Task(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        isDone: json['isDone'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );
}

/// 브레인덤프 인박스 항목. 작업 중 떠오른 딴생각을 여기로 던지고 원래 작업으로 복귀한다.
class BrainDumpItem {
  final String id;
  final String text;
  final DateTime createdAt;

  const BrainDumpItem({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BrainDumpItem.fromJson(Map<String, dynamic> json) => BrainDumpItem(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 완료된 집중 세션 기록 (통계/스트릭용)
class FocusSession {
  final String id;
  final String taskId;
  final String taskTitle;
  final int minutes;
  final DateTime endedAt;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.minutes,
    required this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'minutes': minutes,
        'endedAt': endedAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        taskTitle: json['taskTitle'] as String,
        minutes: json['minutes'] as int,
        endedAt: DateTime.parse(json['endedAt'] as String),
      );
}
