// lib/services/focus_lock_service.dart
import 'dart:io';

import 'package:flutter/services.dart';

/// 폰 앱 잠금. 채널 focusone/lock
/// - iOS: Family Controls (ios/Runner/FocusLock.swift + FocusMonitor 확장). 종료 예약 최소 15분.
/// - Android: 접근성 서비스 (android/.../FocusLockAccessibility.kt). 시간 제한 없음.
class FocusLockService {
  static const _ch = MethodChannel('focusone/lock');

  /// iOS만: 15분 — 호출 지연으로 정확히 15분 세션이 거절되지 않게 10초 허용 (FocusLock.swift와 같게)
  static Duration get minLock =>
      Platform.isIOS ? const Duration(seconds: 15 * 60 - 10) : Duration.zero;

  Future<({bool authorized, int selectedCount})> status() async {
    final m = await _ch.invokeMapMethod<String, dynamic>('status') ?? {};
    return (
      authorized: m['authorized'] == true,
      selectedCount: (m['selectedCount'] as int?) ?? 0,
    );
  }

  /// iOS: 스크린타임 권한 요청 / Android: 접근성 설정 화면 열기(사용자가 직접 켬)
  Future<bool> authorize() async =>
      await _ch.invokeMethod<bool>('authorize') ?? false;

  /// iOS: 시스템 앱 선택 화면 → 선택 개수
  Future<int> pickAppsIOS() async =>
      await _ch.invokeMethod<int>('pickApps') ?? 0;

  /// Android: 홈 화면 앱 목록 / 현재 선택 / 선택 저장
  Future<List<({String package, String label})>> listApps() async => [
        for (final m in await _ch.invokeListMethod<Map>('listApps') ?? const [])
          (package: m['package'] as String, label: m['label'] as String)
      ];
  Future<Set<String>> selection() async =>
      (await _ch.invokeListMethod<String>('selection') ?? const []).toSet();
  Future<int> setSelection(Set<String> apps) async =>
      await _ch.invokeMethod<int>('setSelection', {'apps': apps.toList()}) ?? 0;

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
