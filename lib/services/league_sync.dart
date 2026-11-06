// lib/services/league_sync.dart
// 리그 참여자의 세션을 서버 시계에 예약하고, 끝나면 제출한다. 실패해도 집중에는 영향이 없다.
// 완료 세션은 Growth.leagueOutbox에 저장돼 앱을 꺼도 다음에 다시 보낸다.
import 'package:flutter/foundation.dart';

import '../state/app_state.dart';
import 'ranking_service.dart';

class LeagueSync {
  LeagueSync(this._state, this._service,
      {DateTime Function()? now,
      this.retry = const Duration(seconds: 30),
      this.beginWindow = const Duration(minutes: 1)})
      : _now = now ?? DateTime.now;

  final AppState _state;
  final RankingService _service;
  final DateTime Function() _now;
  final Duration retry;
  final Duration beginWindow; // 시작 뒤 이 안에서만 서버 예약

  String? _begun;
  DateTime _retryAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _sending = false;

  void start() {
    _state.addListener(sync);
    sync();
  }

  void stop() => _state.removeListener(sync);

  /// AppState가 알릴 때와 앱으로 돌아올 때 불린다 (1초마다일 수 있어 가볍게 빠져나간다).
  /// 끝난 세션을 먼저 보내고 새 세션을 예약한다.
  Future<void> sync() async {
    if (!_state.leagueJoined || _sending) return;
    await _flush();
    final a = _state.activeSession;
    if (a == null || !a.isRunning || a.id == _begun) return;
    _begun = a.id;
    // 재실행 복구나 오프라인 시작은 서버가 시작 시각을 잴 수 없다 → 개인 성장만 인정
    if (_now().difference(a.startedAt) > beginWindow) return;
    try {
      await _service.beginFocus(a.id, a.plannedSec);
    } catch (e) {
      debugPrint('league begin: $e');
    }
  }

  Future<void> _flush() async {
    final box = _state.leagueOutbox;
    if (box.isEmpty || _now().isBefore(_retryAt)) return;
    _sending = true;
    try {
      for (final id in box.toList()) {
        try {
          await _service.finishFocus(id);
          _state.leagueSent(id);
        } catch (e) {
          // 네트워크·너무 이름 → 나중에 같은 id로 재시도. 다른 세션은 막지 않는다.
          debugPrint('league finish: $e');
          _retryAt = _now().add(retry);
        }
      }
    } finally {
      _sending = false;
    }
  }
}
