// lib/mobile/mobile_main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../data/local_store.dart';
import '../services/ambient_sound_service.dart';
import '../services/focus_lock_service.dart';
import '../services/session_notifier.dart';
import '../state/app_state.dart';
import 'mobile_shell.dart';

/// 폰(iOS/Android) 진입점. 데스크탑 전용 서비스는 만들지 않는다.
Future<void> runMobile() async {
  // 집중 링 화면은 세로 전용
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
      sound.playAsset(appState.soundAsset);
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

  // 앱 잠금: 진행 중(재생)일 때만 잠그고, 일시정지·그만두기·완료면 해제.
  // iOS는 남은 시간이 15분 미만이면 잠그지 않는다(FocusLockService.minLock).
  final lock = FocusLockService();
  // 이번 재생 구간에 이미 시도했는지(성공 여부 무관) — 매초 틱마다 재시도하지 않게
  String? triedFor;
  var locked = false;
  appState.addListener(() async {
    final a = appState.activeSession;
    final want = appState.lockEnabled && a != null && a.isRunning;
    try {
      if (want && triedFor != a.id) {
        triedFor = a.id;
        final ends =
            DateTime.now().add(Duration(seconds: appState.remainingSeconds));
        locked = await lock.start(a.id, ends);
      } else if (!want && triedFor != null) {
        triedFor = null; // 재개하면 다시 시도
        if (locked) await lock.stop();
        locked = false;
      }
    } catch (_) {
      // 채널 오류여도 집중은 계속
    }
  });

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
