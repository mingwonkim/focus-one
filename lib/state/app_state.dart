// lib/state/app_state.dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../models/blocker_settings.dart';
import '../models/task.dart';

/// 타이머 사이클: 대기 → 집중 → 휴식 → 대기
enum FocusPhase { idle, focus, breakTime }

/// 앱 전역 상태.
/// 원칙: "현재 작업 1개 + 타이머"가 중심. 목록은 보조 데이터.
class AppState extends ChangeNotifier {
  AppState(this._store);

  final LocalStore _store;

  List<Task> _tasks = [];
  List<BrainDumpItem> _inbox = [];
  List<FocusSession> _sessions = [];
  BlockerSettings _blockerSettings = const BlockerSettings();

  String? _currentTaskId;
  Timer? _ticker;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;

  FocusPhase _phase = FocusPhase.idle;
  int _breakTotalSeconds = 5 * 60;
  int _breakRemainingSeconds = 5 * 60;

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
  FocusPhase get phase => _phase;
  BlockerSettings get blockerSettings => _blockerSettings;

  /// 차단이 실제로 켜져야 하는 상태인가 (집중 중 + 타이머 작동 + 설정 on)
  bool get shouldBlock =>
      _phase == FocusPhase.focus && _isRunning && _blockerSettings.enabled;

  int get remainingSeconds =>
      _phase == FocusPhase.breakTime ? _breakRemainingSeconds : _remainingSeconds;
  int get totalSeconds =>
      _phase == FocusPhase.breakTime ? _breakTotalSeconds : _totalSeconds;

  /// 1.0(시작) → 0.0(종료). FocusRing이 이 값으로 원을 줄인다.
  double get progress {
    if (_phase == FocusPhase.breakTime) {
      return _breakTotalSeconds == 0
          ? 0
          : _breakRemainingSeconds / _breakTotalSeconds;
    }
    return _totalSeconds == 0 ? 0 : _remainingSeconds / _totalSeconds;
  }

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
    _blockerSettings = data.blockerSettings;
    // 마지막에 하던 미완료 작업이 있으면 이어서 표시
    final pending = pendingTasks;
    if (pending.isNotEmpty) _currentTaskId = pending.first.id;
    notifyListeners();
  }

  Future<void> _persist() => _store.save(
        StoreData(
          tasks: _tasks,
          inbox: _inbox,
          sessions: _sessions,
          blockerSettings: _blockerSettings,
        ),
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
    if (_phase == FocusPhase.breakTime) return; // 휴식 중엔 skipBreak 먼저
    _phase = FocusPhase.focus;
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
    _phase = FocusPhase.idle;
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
    _persist();
    _startBreak(); // 집중이 끝나면 자동으로 휴식 — 차단도 이때 풀린다
  }

  /// 휴식 시작. 이 동안 차단은 비활성 (shouldBlock == false).
  void _startBreak() {
    _phase = FocusPhase.breakTime;
    _breakRemainingSeconds = _breakTotalSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_breakRemainingSeconds <= 1) {
        _endBreak();
      } else {
        _breakRemainingSeconds--;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void _endBreak() {
    _ticker?.cancel();
    _phase = FocusPhase.idle;
    _breakRemainingSeconds = _breakTotalSeconds;
    onBreakEnd?.call();
    notifyListeners();
  }

  /// 휴식 건너뛰고 바로 대기 상태로
  void skipBreak() {
    if (_phase != FocusPhase.breakTime) return;
    _endBreak();
  }

  void setBreakMinutes(int minutes) {
    _breakTotalSeconds = minutes * 60;
    if (_phase != FocusPhase.breakTime) {
      _breakRemainingSeconds = _breakTotalSeconds;
    }
    notifyListeners();
  }

  /// 휴식 종료 콜백 (알림용, main에서 주입)
  void Function()? onBreakEnd;

  // ---- Blocker 설정 ----
  void setBlockerEnabled(bool enabled) {
    _blockerSettings = _blockerSettings.copyWith(enabled: enabled);
    notifyListeners();
    _persist();
  }

  void setBlockerAutoKill(bool autoKill) {
    _blockerSettings = _blockerSettings.copyWith(autoKill: autoKill);
    notifyListeners();
    _persist();
  }

  void addBlockedApp(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _blockerSettings.apps.contains(trimmed)) return;
    _blockerSettings = _blockerSettings.copyWith(
      apps: [..._blockerSettings.apps, trimmed],
    );
    notifyListeners();
    _persist();
  }

  void removeBlockedApp(String name) {
    _blockerSettings = _blockerSettings.copyWith(
      apps: _blockerSettings.apps.where((a) => a != name).toList(),
    );
    notifyListeners();
    _persist();
  }

  void addBlockedSite(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty || _blockerSettings.sites.contains(trimmed)) return;
    _blockerSettings = _blockerSettings.copyWith(
      sites: [..._blockerSettings.sites, trimmed],
    );
    notifyListeners();
    _persist();
  }

  void removeBlockedSite(String keyword) {
    _blockerSettings = _blockerSettings.copyWith(
      sites: _blockerSettings.sites.where((s) => s != keyword).toList(),
    );
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
