// lib/main.dart
import 'package:flutter/material.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'data/local_store.dart';
import 'models/task.dart';
import 'services/hotkey_service.dart';
import 'services/tray_service.dart';
import 'services/window_service.dart';
import 'state/app_state.dart';

final _hotkeyService = HotkeyService();
final _trayService = TrayService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 창 초기화 (미니 위젯, always-on-top, frameless)
  final windowService = WindowService();
  await windowService.initMiniWindow();

  // 2. 데스크탑 알림 초기화
  await localNotifier.setup(appName: 'FocusOne');

  // 3. 앱 상태 로드
  final appState = AppState(LocalStore());
  await appState.init();

  // 세션 완료 → 데스크탑 알림
  appState.onSessionComplete = (Task task, int minutes) {
    LocalNotification(
      title: '집중 완료!',
      body: '"${task.title}" $minutes분 집중했어요. 잠깐 쉬어가세요.',
    ).show();
  };

  // 4. 트레이 상주 (창 닫기 ≠ 종료, 트레이 메뉴에서만 실제 종료)
  await _trayService.init();
  _trayService.onShowRequested = windowService.bringToFront;
  _trayService.onQuitRequested = () async {
    await _hotkeyService.dispose();
    _trayService.dispose();
    await windowManager.destroy();
  };

  // 5. 전역 단축키 (Ctrl+Shift+Space → 브레인덤프 캡처)
  _hotkeyService.onQuickCapture = windowService.showCapture;
  await _hotkeyService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: windowService),
      ],
      child: const FocusOneApp(),
    ),
  );
}
