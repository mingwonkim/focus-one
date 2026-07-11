// lib/state/app_state.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../models/task.dart';

/// 앱 전역 상태.
/// 원칙: "현재 작업 1개 + 타이머"가 중심. 목록은 보조 데이터.
class AppState extends ChangeNotifier {
  AppState(this._store);

  final LocalStore _store;

  List<Task> _tasks = [];
  List<BrainDumpItem> _inbox = [];
  List<FocusSession> _sessions = [];

  String? _currentTaskId;
  Timer? _ticker;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;

  // ---- Getters ----
  List<Task> get pendingTasks =>
      _tasks.where((t) => !t.isDone).toList(growable: false);
  List<BrainDumpItem> get inbox => List.unmodifiable(_inbox);
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Task? get currentTask {
    if (_currentTaskId == null) return null;
    for (final t in _tasks) {
      if (t.id == _currentTaskId && !t.isDone) return t;
    }
    return null;
  }

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;

  /// 1.0(시작) → 0.0(종료). FocusRing이 이 값으로 원을 줄인다.
  double get progress =>
      _totalSeconds == 0 ? 0 : _remainingSeconds / _totalSeconds;

  /// 오늘 완료한 집중 시간(분)
  int get todayFocusMinutes {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.endedAt.year == now.year &&
            s.endedAt.month == now.month &&
            s.endedAt.day == now.day)
        .fold(0, (sum, s) => sum + s.minutes);
  }

  /// 연속 집중일 스트릭
  int get streakDays {
    if (_sessions.isEmpty) return 0;
    final days = _sessions
        .map((s) => DateTime(s.endedAt.year, s.endedAt.month, s.endedAt.day))
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    // 오늘 기록이 없으면 어제부터 카운트
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 세션 완료 콜백 (알림/사운드 트리거용, main에서 주입)
  void Function(Task task, int minutes)? onSessionComplete;

  // ---- 초기화 ----
  Future<void> init() async {
    final data = await _store.load();
    _tasks = List.of(data.tasks);
    _inbox = List.of(data.inbox);
    _sessions = List.of(data.sessions);
    // 마지막에 하던 미완료 작업이 있으면 이어서 표시
    final pending = pendingTasks;
    if (pending.isNotEmpty) _currentTaskId = pending.first.id;
    notifyListeners();
  }

  Future<void> _persist() => _store.save(
        StoreData(tasks: _tasks, inbox: _inbox, sessions: _sessions),
      );

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ---- Task ----
  void addTask(String title, {bool setAsCurrent = false}) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final task = Task(id: _newId(), title: trimmed, createdAt: DateTime.now());
    _tasks.add(task);
    if (setAsCurrent || _currentTaskId == null) {
      _currentTaskId = task.id;
    }
    notifyListeners();
    _persist();
  }

  void selectTask(String id) {
    if (_currentTaskId == id) return;
    stopTimer(); // 작업 전환 시 타이머 리셋 — "하나만" 원칙
    _currentTaskId = id;
    notifyListeners();
  }

  void completeCurrentTask() {
    final task = currentTask;
    if (task == null) return;
    final wasRunning = _isRunning;
    final focusedMinutes = ((_totalSeconds - _remainingSeconds) / 60).round();
    stopTimer();
    _tasks = _tasks
        .map((t) => t.id == task.id
            ? t.copyWith(isDone: true, completedAt: DateTime.now())
            : t)
        .toList();
    // 진행 중이던 시간도 세션으로 기록 (1분 이상일 때)
    if (wasRunning && focusedMinutes >= 1) {
      _recordSession(task, focusedMinutes);
    }
    // 다음 작업 자동 선택은 하지 않는다 — 사용자가 직접 고르게 해서
    // "끝냈다"는 완결감을 준다.
    _currentTaskId = null;
    notifyListeners();
    _persist();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    if (_currentTaskId == id) {
      stopTimer();
      _currentTaskId = null;
    }
    notifyListeners();
    _persist();
  }

  // ---- Brain Dump ----
  void addToInbox(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _inbox.insert(
      0,
      BrainDumpItem(id: _newId(), text: trimmed, createdAt: DateTime.now()),
    );
    notifyListeners();
    _persist();
  }

  /// 인박스 항목을 정식 작업으로 승격
  void promoteInboxItem(String id) {
    final idx = _inbox.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final item = _inbox.removeAt(idx);
    addTask(item.text);
  }

  void deleteInboxItem(String id) {
    _inbox.removeWhere((i) => i.id == id);
    notifyListeners();
    _persist();
  }

  // ---- Timer ----
  void setDurationMinutes(int minutes) {
    if (_isRunning) return;
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void startTimer() {
    if (currentTask == null || _isRunning) return;
    _isRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _finishSession();
      } else {
        _remainingSeconds--;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pauseTimer() {
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void stopTimer() {
    _ticker?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void _finishSession() {
    final task = currentTask;
    final minutes = (_totalSeconds / 60).round();
    _ticker?.cancel();
    _isRunning = false;
    _remainingSeconds = _totalSeconds;
    if (task != null) {
      _recordSession(task, minutes);
      onSessionComplete?.call(task, minutes);
    }
    notifyListeners();
    _persist();
  }

  void _recordSession(Task task, int minutes) {
    _sessions.add(FocusSession(
      id: _newId(),
      taskId: task.id,
      taskTitle: task.title,
      minutes: minutes,
      endedAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
