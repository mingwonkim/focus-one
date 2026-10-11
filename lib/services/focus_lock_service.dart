// lib/services/focus_lock_service.dart
import 'package:flutter/services.dart';

/// 폰 앱 잠금 (iOS Family Controls). 네이티브: ios/Runner/FocusLock.swift
/// iOS는 세션 종료 시각 예약 최소 15분 → 그보다 짧으면 잠그지 않는다.
class FocusLockService {
  static const _ch = MethodChannel('focusone/lock');
  static const minLock = Duration(minutes: 15);

  Future<({bool authorized, int selectedCount})> status() async {
    final m = await _ch.invokeMapMethod<String, dynamic>('status') ?? {};
    return (
      authorized: m['authorized'] == true,
      selectedCount: (m['selectedCount'] as int?) ?? 0,
    );
  }

  Future<bool> authorize() async =>
      await _ch.invokeMethod<bool>('authorize') ?? false;

  /// 시스템 앱 선택 화면 → 선택 개수
  Future<int> pickApps() async => await _ch.invokeMethod<int>('pickApps') ?? 0;

  Future<bool> start(String sessionId, DateTime endsAt) async {
    if (endsAt.difference(DateTime.now()) < minLock) return false;
    return await _ch.invokeMethod<bool>('start', {
          'sessionId': sessionId,
          'endsAtMs': endsAt.millisecondsSinceEpoch,
        }) ??
        false;
  }

  Future<void> stop() => _ch.invokeMethod('stop');
}
