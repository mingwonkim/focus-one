// lib/state/app_state.dart
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../core/design_tokens.dart';
import '../data/local_store.dart';
import '../models/blocker_settings.dart';
import '../models/collection.dart';
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
  int _totalSeconds = 25 * 60; // 다음 세션 길이 설정
  ActiveSession? _active; // 진행/일시정지 중인 세션 (저장됨)
  Progress _progress = const Progress(); // 폰: 태그·친구·풍경·물방울
  FocusSession? _lastReward; // 방금 완료한 세션 (보상 시트 표시용, 저장 안 함)

  int _breakTotalSeconds = 5 * 60;
  DateTime? _breakEndsAt; // 휴식 중일 때만 (저장 안 함 — 꺼지면 휴식은 버린다)

  FocusScene _scene = FocusScene.forest;
  bool _soundEnabled = true;
  double _soundVolume = 0.6;

  // ---- Getters ----
  List<Task> get pendingTasks =>
      _tasks.where((t) => !t.isDone).toList(growable: false);

  /// 오늘 완료한 작업 (리스트 하단에 취소선으로 표시)
  List<Task> get todayDoneTasks {
    final now = DateTime.now();
    return _tasks
        .where((t) =>
            t.isDone &&
            t.completedAt != null &&
            t.completedAt!.year == now.year &&
            t.completedAt!.month == now.month &&
            t.completedAt!.day == now.day)
        .toList(growable: false);
  }

  /// 작업별 완료한 집중 세션 수 (🍅 카운트)
  int sessionCountFor(String taskId) => _sessions
      .where((s) => s.taskId == taskId && s.outcome == SessionOutcome.completed)
      .length;

  /// 오늘 완료한 집중 세션 수 (푸터: 심은 나무/모은 별/만난 고래)
  int get todaySessionCount {
    final now = DateTime.now();
    return _sessions
        .where((s) =>
            s.outcome == SessionOutcome.completed &&
            s.endedAt.year == now.year &&
            s.endedAt.month == now.month &&
            s.endedAt.day == now.day)
        .length;
  }
  List<BrainDumpItem> get inbox => List.unmodifiable(_inbox);
  List<FocusSession> get sessions => List.unmodifiable(_sessions);

  Task? get currentTask {
    if (_currentTaskId == null) return null;
    for (final t in _tasks) {
      if (t.id == _currentTaskId && !t.isDone) return t;
    }
    return null;
  }

  bool get isRunning => _active?.isRunning ?? false;
  FocusPhase get phase => _breakEndsAt != null
      ? FocusPhase.breakTime
      : (_active != null ? FocusPhase.focus : FocusPhase.idle);
  ActiveSession? get activeSession => _active;
  BlockerSettings get blockerSettings => _blockerSettings;
  FocusScene get scene => _scene;

  void setScene(FocusScene scene) {
    if (_scene == scene) return;
    _scene = scene;
    notifyListeners();
    _persist();
  }

  bool get soundEnabled => _soundEnabled;
  double get soundVolume => _soundVolume;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
    _persist();
  }

  /// 슬라이더 드래그 중엔 persist:false로 호출하고 놓을 때 저장한다 (파일 쓰기 폭주 방지)
  void setSoundVolume(double volume, {bool persist = true}) {
    _soundVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
    if (persist) _persist();
  }

  /// 차단이 실제로 켜져야 하는 상태인가 (집중 중 + 타이머 작동 + 설정 on)
  bool get shouldBlock =>
      phase == FocusPhase.focus && isRunning && _blockerSettings.enabled;

  int get remainingSeconds {
    final now = clock.now();
    if (_breakEndsAt != null) {
      return _breakEndsAt!.difference(now).inSeconds.clamp(0, _breakTotalSeconds);
    }
    return _active?.remainingSec(now) ?? _totalSeconds;
  }

  int get totalSeconds => _breakEndsAt != null
      ? _breakTotalSeconds
      : (_active?.plannedSec ?? _totalSeconds);

  /// 1.0(시작) → 0.0(종료). FocusRing이 이 값으로 원을 줄인다.
  double get progress =>
      totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;

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
    _scene = data.scene;
    _soundEnabled = data.soundEnabled;
    _soundVolume = data.soundVolume;
    _progress = data.progress;
    // 마지막에 하던 미완료 작업이 있으면 이어서 표시
    final pending = pendingTasks;
    if (pending.isNotEmpty) _currentTaskId = pending.first.id;
    // 꺼지기 전 진행 중이던 세션 복구: 이미 끝났으면 완료 처리(휴식 없이), 아니면 이어서
    _active = data.activeSession;
    if (_active != null) {
      if (pending.any((t) => t.id == _active!.taskId)) {
        _currentTaskId = _active!.taskId;
      }
      if (_active!.remainingSec(clock.now()) <= 0) {
        _finishSession(startBreak: false);
      } else if (_active!.isRunning) {
        _startTicker();
      }
    }
    notifyListeners();
  }

  Future<void> _persist() => _store.save(
        StoreData(
          tasks: _tasks,
          inbox: _inbox,
          sessions: _sessions,
          blockerSettings: _blockerSettings,
          scene: _scene,
          soundEnabled: _soundEnabled,
          soundVolume: _soundVolume,
          activeSession: _active,
          progress: _progress,
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

  /// 폰: 할 일 없이 태그만으로 집중
  void clearCurrentTask() {
    if (_active != null) return;
    _currentTaskId = null;
    notifyListeners();
  }

  void completeCurrentTask() {
    final task = currentTask;
    if (task == null) return;
    // 진행 중이던 시간은 조기 완료로 기록 (1분 이상일 때)
    if (_active != null && _active!.focusedSec(clock.now()) >= 60) {
      _recordSession(SessionOutcome.early);
    }
    _cancelSession();
    _tasks = _tasks
        .map((t) => t.id == task.id
            ? t.copyWith(isDone: true, completedAt: DateTime.now())
            : t)
        .toList();
    // 다음 작업 자동 선택은 하지 않는다 — 사용자가 직접 고르게 해서
    // "끝냈다"는 완결감을 준다.
    _currentTaskId = null;
    notifyListeners();
    _persist();
  }

  /// 리스트 체크로 완료. 현재 작업이 아니면 타이머·선택을 건드리지 않는다.
  void completeTask(String id) {
    if (id == _currentTaskId) return completeCurrentTask();
    _tasks = _tasks
        .map((t) => t.id == id
            ? t.copyWith(isDone: true, completedAt: DateTime.now())
            : t)
        .toList();
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
  // 남은 시간은 항상 시계로 계산한다. 1초 타이머는 화면 갱신·종료 감지용일 뿐.
  void setDurationMinutes(int minutes) {
    if (_active != null) return; // 진행·일시정지 중엔 길이 변경 불가
    _totalSeconds = minutes * 60;
    notifyListeners();
  }

  /// [allowNoTask] 폰: 할 일 없이 태그만으로 시작 허용 (데스크탑은 할 일 필수)
  void startTimer({bool allowNoTask = false}) {
    final task = currentTask;
    if ((task == null && !allowNoTask) || isRunning || _breakEndsAt != null) {
      return;
    }
    final now = clock.now();
    _active = _active?.resumed(now) ??
        ActiveSession(
          id: _newId(),
          taskId: task?.id ?? '',
          taskTitle: task?.title ?? '',
          scene: _scene.name,
          startedAt: now,
          plannedSec: _totalSeconds,
          resumedAt: now,
          tagId: task?.tagId ?? _progress.currentTagId,
          companionId: selectedCompanion.id,
        );
    _startTicker();
    notifyListeners();
    _persist();
  }

  void pauseTimer() {
    if (!isRunning) return;
    _ticker?.cancel();
    _active = _active!.paused(clock.now());
    notifyListeners();
    _persist();
  }

  /// 리셋: 기록 없이 세션을 버린다 (데스크탑 ↺)
  void stopTimer() {
    _breakEndsAt = null;
    _cancelSession();
    notifyListeners();
    _persist();
  }

  /// 그만두기: 집중한 만큼 기록은 남기고 보상은 없음 (폰)
  void abandonSession() {
    if (_active == null) return;
    if (_active!.focusedSec(clock.now()) >= 60) {
      _recordSession(SessionOutcome.abandoned);
    }
    stopTimer();
  }

  void _cancelSession() {
    _ticker?.cancel();
    _active = null;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_breakEndsAt != null) {
        if (remainingSeconds <= 0) return _endBreak();
      } else if (_active != null && _active!.remainingSec(clock.now()) <= 0) {
        return _finishSession();
      }
      notifyListeners();
    });
  }

  /// 끝까지 완료. 세션 ID로 기록하므로 재실행·복귀가 겹쳐도 한 번만 남는다.
  void _finishSession({bool startBreak = true}) {
    final active = _active;
    if (active == null) return;
    _recordSession(SessionOutcome.completed);
    _cancelSession();
    final task = _tasks.where((t) => t.id == active.taskId).firstOrNull;
    if (task != null) onSessionComplete?.call(task, active.plannedSec ~/ 60);
    if (startBreak) {
      _startBreak(); // 집중이 끝나면 자동으로 휴식 — 차단도 이때 풀린다
    } else {
      notifyListeners();
    }
    _persist();
  }

  /// 휴식 시작. 이 동안 차단은 비활성 (shouldBlock == false).
  void _startBreak() {
    _breakEndsAt = clock.now().add(Duration(seconds: _breakTotalSeconds));
    _startTicker();
    notifyListeners();
  }

  void _endBreak() {
    _ticker?.cancel();
    _breakEndsAt = null;
    onBreakEnd?.call();
    notifyListeners();
  }

  /// 휴식 건너뛰고 바로 대기 상태로
  void skipBreak() {
    if (_breakEndsAt == null) return;
    _endBreak();
  }

  void setBreakMinutes(int minutes) {
    _breakTotalSeconds = minutes * 60;
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

  /// 진행 세션을 기록으로 확정 (같은 세션 ID는 한 번만)
  void _recordSession(SessionOutcome outcome) {
    final a = _active;
    if (a == null || _sessions.any((s) => s.id == a.id)) return;
    final now = clock.now();
    final focused = outcome == SessionOutcome.completed
        ? a.plannedSec
        : a.focusedSec(now);
    _sessions.add(FocusSession(
      id: a.id,
      taskId: a.taskId,
      taskTitle: a.taskTitle,
      minutes: (focused / 60).round(),
      endedAt: now,
      startedAt: a.startedAt,
      focusedSec: focused,
      scene: a.scene,
      outcome: outcome,
      tagId: a.tagId,
      companionId: outcome == SessionOutcome.completed ? a.companionId : null,
    ));
    // 보상: 끝까지 완료한 세션만 — 친구 1 + 물방울(실집중 분). 기록과 같은 저장으로 확정.
    if (outcome == SessionOutcome.completed) {
      final owned = Map.of(_progress.owned);
      if (a.companionId != null) {
        owned[a.companionId!] = (owned[a.companionId!] ?? 0) + 1;
      }
      _progress = _progress.copyWith(
          owned: owned, drops: _progress.drops + focused ~/ 60);
      _lastReward = _sessions.last;
    }
  }

  // ---- 폰: 태그 · 친구 · 풍경 · 상점 ----
  List<Tag> get tags => _progress.tags;
  Tag? get currentTag =>
      _progress.tags.where((t) => t.id == _progress.currentTagId).firstOrNull;
  int get drops => _progress.drops;
  int ownedCount(String itemId) => _progress.owned[itemId] ?? 0;
  FocusSession? get lastReward => _lastReward;
  void clearLastReward() {
    _lastReward = null;
    notifyListeners();
  }

  void _setProgress(Progress p) {
    _progress = p;
    notifyListeners();
    _persist();
  }

  void addTag(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    final tag = Tag(id: _newId(), name: n, colorIndex: _progress.tags.length);
    _setProgress(_progress.copyWith(
        tags: [..._progress.tags, tag], currentTagId: () => tag.id));
  }

  void renameTag(String id, String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    _setProgress(_progress.copyWith(
        tags: [for (final t in _progress.tags) t.id == id ? t.copyWith(name: n) : t]));
  }

  /// 태그 삭제: 지난 기록의 tagId는 그대로 둔다(통계에서 "삭제된 태그"로 묶음)
  void deleteTag(String id) {
    final rest = _progress.tags.where((t) => t.id != id).toList();
    if (rest.isEmpty) return; // 마지막 태그는 지우지 않는다
    _tasks = [
      for (final t in _tasks) t.tagId == id ? Task(id: t.id, title: t.title, isDone: t.isDone, createdAt: t.createdAt, completedAt: t.completedAt) : t
    ];
    _setProgress(_progress.copyWith(
        tags: rest,
        currentTagId: () =>
            _progress.currentTagId == id ? rest.first.id : _progress.currentTagId));
  }

  void selectTag(String id) =>
      _setProgress(_progress.copyWith(currentTagId: () => id));

  void setTaskTag(String taskId, String tagId) {
    _tasks = [for (final t in _tasks) t.id == taskId ? t.copyWith(tagId: tagId) : t];
    notifyListeners();
    _persist();
  }

  /// 장면별 누적 완료 집중 분 (친구 해금 기준)
  int sceneMinutes(FocusScene s) => _sessions
      .where((x) => x.outcome == SessionOutcome.completed && x.scene == s.name)
      .fold(0, (sum, x) => sum + (x.focusedSec ?? x.minutes * 60) ~/ 60);

  bool isUnlocked(Companion c) => sceneMinutes(c.scene) >= c.unlockMinutes;

  /// 이번 세션에 데려올 친구 — 선택이 현재 장면과 다르거나 잠겨 있으면 장면 첫 친구
  Companion get selectedCompanion {
    final c = Companion.byId(_progress.selectedCompanionId);
    if (c != null && c.scene == _scene && isUnlocked(c)) return c;
    return Companion.of(_scene).first;
  }

  void selectCompanion(String id) {
    final c = Companion.byId(id);
    if (c == null || !isUnlocked(c) || _active != null) return;
    _setProgress(_progress.copyWith(selectedCompanionId: () => id));
  }

  bool buyDecor(String id) {
    final d = Decor.byId(id);
    if (d == null || _progress.drops < d.price) return false;
    final owned = Map.of(_progress.owned)..[id] = (_progress.owned[id] ?? 0) + 1;
    _setProgress(_progress.copyWith(owned: owned, drops: _progress.drops - d.price));
    return true;
  }

  List<Placement> placementsOf(FocusScene s) =>
      _progress.placements[s.name] ?? const [];

  int placedCount(String itemId) => _progress.placements.values
      .expand((l) => l)
      .where((p) => p.itemId == itemId)
      .length;

  /// 빈 칸에만, 보유 수를 넘지 않게 배치
  bool place(FocusScene s, String itemId, int x, int y) {
    final list = placementsOf(s);
    final inGrid = x >= 0 && y >= 0 && x < Placement.grid && y < Placement.grid;
    if (!inGrid || list.any((p) => p.x == x && p.y == y)) return false;
    if (placedCount(itemId) >= ownedCount(itemId)) return false;
    _setProgress(_progress.copyWith(placements: {
      ..._progress.placements,
      s.name: [...list, Placement(itemId, x, y)],
    }));
    return true;
  }

  /// 회수: 보관함으로 돌아갈 뿐 재지급·삭제 없음
  void unplace(FocusScene s, int x, int y) {
    _setProgress(_progress.copyWith(placements: {
      ..._progress.placements,
      s.name: placementsOf(s).where((p) => p.x != x || p.y != y).toList(),
    }));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
