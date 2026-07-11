// lib/services/hotkey_service.dart
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// 전역 단축키: Ctrl+Shift+Space (macOS는 Cmd+Shift+Space 대응은 추후)
/// 다른 앱을 쓰다가도 떠오른 생각을 즉시 인박스로 던질 수 있게 한다.
class HotkeyService {
  void Function()? onQuickCapture;

  Future<void> init() async {
    try {
      await hotKeyManager.unregisterAll();
      final hotKey = HotKey(
        key: PhysicalKeyboardKey.space,
        modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => onQuickCapture?.call(),
      );
    } catch (_) {
      // 단축키 등록 실패(다른 앱 선점 등)해도 앱은 계속 동작
    }
  }

  Future<void> dispose() async {
    await hotKeyManager.unregisterAll();
  }
}
