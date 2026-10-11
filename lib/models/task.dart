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

/// 세션 결과: 끝까지 완료 / 작업 완료로 조기 종료 / 그만두기
enum SessionOutcome { completed, early, abandoned }

/// 끝난 집중 세션 기록 (통계/스트릭용).
/// startedAt·focusedSec·scene은 v2(모바일)부터 기록 — 구기록은 null이고 통계에서 지어내지 않는다.
class FocusSession {
  final String id; // 진행 세션 ID와 같음 → 같은 세션은 한 번만 기록
  final String taskId;
  final String taskTitle;
  final int minutes;
  final DateTime endedAt;
  final DateTime? startedAt;
  final int? focusedSec;
  final String? scene;
  final SessionOutcome outcome;

  const FocusSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.minutes,
    required this.endedAt,
    this.startedAt,
    this.focusedSec,
    this.scene,
    this.outcome = SessionOutcome.completed,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'minutes': minutes,
        'endedAt': endedAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'focusedSec': focusedSec,
        'scene': scene,
        'outcome': outcome.name,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        taskTitle: json['taskTitle'] as String,
        minutes: json['minutes'] as int,
        endedAt: DateTime.parse(json['endedAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        focusedSec: json['focusedSec'] as int?,
        scene: json['scene'] as String?,
        outcome: SessionOutcome.values.asNameMap()[json['outcome']] ??
            SessionOutcome.completed,
      );
}

/// 진행 중인 집중 세션 스냅샷 — 저장해 두고 앱이 꺼졌다 켜져도 이어간다.
/// 남은 시간은 매번 시계로 계산한다(1초씩 깎지 않음 → 백그라운드·재실행에도 정확).
class ActiveSession {
  final String id;
  final String taskId;
  final String taskTitle;
  final String scene;
  final DateTime startedAt;
  final int plannedSec;
  final int accumulatedSec; // 마지막 일시정지까지 쌓인 집중 초
  final DateTime? resumedAt; // null = 일시정지 중

  const ActiveSession({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.scene,
    required this.startedAt,
    required this.plannedSec,
    this.accumulatedSec = 0,
    this.resumedAt,
  });

  bool get isRunning => resumedAt != null;

  /// 실제 집중 초. 시계가 뒤로 가도 0~계획 시간 안으로 자른다.
  int focusedSec(DateTime now) => (accumulatedSec +
          (resumedAt == null ? 0 : now.difference(resumedAt!).inSeconds))
      .clamp(0, plannedSec);

  int remainingSec(DateTime now) => plannedSec - focusedSec(now);

  ActiveSession paused(DateTime now) => ActiveSession(
        id: id,
        taskId: taskId,
        taskTitle: taskTitle,
        scene: scene,
        startedAt: startedAt,
        plannedSec: plannedSec,
        accumulatedSec: focusedSec(now),
      );

  ActiveSession resumed(DateTime now) => ActiveSession(
        id: id,
        taskId: taskId,
        taskTitle: taskTitle,
        scene: scene,
        startedAt: startedAt,
        plannedSec: plannedSec,
        accumulatedSec: accumulatedSec,
        resumedAt: now,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'scene': scene,
        'startedAt': startedAt.toIso8601String(),
        'plannedSec': plannedSec,
        'accumulatedSec': accumulatedSec,
        'resumedAt': resumedAt?.toIso8601String(),
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        taskTitle: json['taskTitle'] as String,
        scene: json['scene'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        plannedSec: json['plannedSec'] as int,
        accumulatedSec: json['accumulatedSec'] as int? ?? 0,
        resumedAt: json['resumedAt'] != null
            ? DateTime.parse(json['resumedAt'] as String)
            : null,
      );
}
