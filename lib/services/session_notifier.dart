// lib/services/session_notifier.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../state/app_state.dart';

/// 폰: 세션 종료 시각에 로컬 알림 1개. 일시정지·그만두기·완료면 취소, 재개하면 다시 예약.
/// 알림 도착은 완료 처리가 아니다 — 완료 기록은 앱이 켜질 때 AppState가 시각으로 확정한다.
class SessionNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1;
  static const _breakId = 2;
  static const _breakChannel = MethodChannel('focusone/break');
  DateTime? _breakShown; // 휴식 남은 시간 표시 중이면 종료 시각
  String? _scheduledFor; // "세션ID@종료시각" — 같은 예약 반복 방지
  bool _asked = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // 첫 집중 시작 때 묻는다
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// AppState 변화마다 호출
  Future<void> sync(AppState s) async {
    await _syncBreak(s);
    final a = s.activeSession;
    if (a == null || !a.isRunning) {
      if (_scheduledFor != null) {
        _scheduledFor = null;
        await _plugin.cancel(id: _id);
      }
      return;
    }
    final endsAt = DateTime.now().add(Duration(seconds: s.remainingSeconds));
    final key = '${a.id}@${endsAt.millisecondsSinceEpoch ~/ 60000}';
    if (key == _scheduledFor) return;
    _scheduledFor = key;
    if (!_asked) {
      _asked = true;
      await _requestPermission();
    }
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: tz.TZDateTime.from(endsAt, tz.UTC),
      title: '집중 완료',
      body: a.taskTitle.isEmpty ? '친구가 기다려요. 열어서 데려오세요.' : '"${a.taskTitle}" 끝! 친구를 데려오세요.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('session', '집중 종료',
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      // 정확 알람 권한 없이도 동작 (몇 분 늦을 수 있음)
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 휴식 중: iOS는 Dynamic Island·잠금 화면(Live Activity), Android는 줄어드는 시계 알림
  Future<void> _syncBreak(AppState s) async {
    if (s.phase != FocusPhase.breakTime) {
      if (_breakShown == null) return;
      _breakShown = null;
      if (Platform.isIOS) {
        await _breakChannel.invokeMethod('end');
      } else {
        await _plugin.cancel(id: _breakId);
      }
      return;
    }
    final endsAt = DateTime.now().add(Duration(seconds: s.remainingSeconds));
    // 매 초 호출되니 시각이 실제로 바뀐 경우(휴식 시작·시간 변경)만 다시 띄운다
    if (_breakShown != null && endsAt.difference(_breakShown!).inSeconds.abs() < 3) return;
    _breakShown = endsAt;
    if (Platform.isIOS) {
      await _breakChannel.invokeMethod('start', {'endsAt': endsAt.millisecondsSinceEpoch.toDouble()});
      return;
    }
    await _plugin.show(
      id: _breakId,
      title: '휴식 중',
      body: '끝나면 다시 집중해요',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('break', '휴식 남은 시간',
            importance: Importance.low,
            ongoing: true,
            onlyAlertOnce: true,
            showWhen: true,
            when: endsAt.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            timeoutAfter: s.remainingSeconds * 1000),
      ),
    );
  }
}
