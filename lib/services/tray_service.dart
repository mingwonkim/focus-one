// lib/services/tray_service.dart
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

/// 시스템 트레이 상주. 창을 닫아도 트레이에서 되살릴 수 있다.
class TrayService with TrayListener {
  void Function()? onShowRequested;
  void Function()? onQuitRequested;

  Future<void> init() async {
    trayManager.addListener(this);
    try {
      // Windows는 .ico, macOS/Linux는 .png 필요
      final iconPath = Platform.isWindows
          ? 'assets/tray_icon.ico'
          : 'assets/tray_icon.png';
      await trayManager.setIcon(iconPath);
      await trayManager.setContextMenu(Menu(items: [
        MenuItem(key: 'show', label: '열기'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: '종료'),
      ]));
      await trayManager.setToolTip('FocusOne — 지금 이거 하나만');
    } catch (_) {
      // 아이콘 파일이 없어도 앱 자체는 동작해야 한다
    }
  }

  @override
  void onTrayIconMouseDown() {
    onShowRequested?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        onShowRequested?.call();
      case 'quit':
        onQuitRequested?.call();
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
