// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/design_tokens.dart';
import 'features/capture/quick_capture_overlay.dart';
import 'features/expanded/expanded_screen.dart';
import 'features/mini/mini_widget_screen.dart';
import 'services/window_service.dart';

class FocusOneApp extends StatelessWidget {
  const FocusOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusOne',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AppShell(),
    );
  }
}

/// 창 모드(mini/expanded/capture)에 따라 화면을 전환하는 셸.
/// 라우팅 대신 단일 창 안에서 AnimatedSwitcher로 처리한다.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final windowService = context.watch<WindowService>();

    final Widget child = switch (windowService.mode) {
      WindowMode.mini => const MiniWidgetScreen(),
      WindowMode.expanded => const ExpandedScreen(),
      WindowMode.capture => QuickCaptureOverlay(
          onClose: () => windowService.closeCapture(),
        ),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedSwitcher(
        duration: AppDuration.enter,
        child: KeyedSubtree(
          key: ValueKey(windowService.mode),
          child: child,
        ),
      ),
    );
  }
}
