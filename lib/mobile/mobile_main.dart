// lib/mobile/mobile_main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/local_store.dart';
import '../services/ambient_sound_service.dart';
import '../services/session_notifier.dart';
import '../state/app_state.dart';
import 'mobile_shell.dart';

/// 폰(iOS/Android) 진입점. 데스크탑 전용 서비스는 만들지 않는다.
Future<void> runMobile() async {
  final appState = AppState(LocalStore())
    ..autoBreak = false; // 폰: 휴식은 보상 시트에서 선택
  await appState.init();

  // 집중 중에만 장면 사운드 (데스크탑과 같은 규칙)
  final sound = AmbientSoundService();
  appState.addListener(() {
    sound.setVolume(appState.soundVolume);
    if (appState.phase == FocusPhase.focus &&
        appState.isRunning &&
        appState.soundEnabled) {
      sound.play(appState.scene);
    } else {
      sound.stop();
    }
  });

  // 세션 종료 알림 (거부돼도 앱은 정상 동작)
  final notifier = SessionNotifier();
  try {
    await notifier.init();
    appState.addListener(() => notifier.sync(appState));
  } catch (_) {}

  runApp(
      ChangeNotifierProvider.value(value: appState, child: const MobileApp()));
}

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scene = context.select((AppState s) => s.scene);
    return MaterialApp(
      title: 'FocusOne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(scene),
      home: const MobileShell(),
    );
  }
}
