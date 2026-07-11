// lib/services/blocker_service.dart
import 'dart:async';
import 'dart:io';

import '../models/blocker_settings.dart';

/// 집중 세션 중 방해 앱/사이트 감지.
///
/// 동작 방식 (3초 폴링):
/// 1. 실행 중인 프로세스 목록에서 차단 앱 이름 매칭
/// 2. 활성 창(브라우저 탭) 제목에서 차단 사이트 키워드 매칭
/// 3. 감지 시 onViolation 콜백 → 경고 알림 (autoKill이면 프로세스 종료)
///
/// 플랫폼별 구현:
/// - Windows: tasklist / taskkill / PowerShell GetForegroundWindow
/// - macOS:   ps / pkill / osascript (창 제목은 손쉬운 사용 권한 필요)
/// - Linux:   ps / pkill / xdotool (X11, 설치되어 있을 때만)
///
/// 한계: 브라우저 "사이트 차단"은 창 제목 기반 감지라 우회 가능한
/// 소프트 차단이다. hosts 파일/확장 프로그램 방식의 하드 차단은 Phase 2+.
class BlockerService {
  Timer? _timer;
  BlockerSettings _settings = const BlockerSettings();

  /// 같은 대상에 대한 반복 경고 방지 (세션 시작 시 초기화)
  final Set<String> _warned = {};

  /// 감지 콜백: (대상 이름, 종료 처리 여부)
  void Function(String target, bool killed)? onViolation;

  bool get isActive => _timer != null;

  /// 폴링 시작. 이미 돌고 있으면 설정만 갱신 (idempotent).
  void start(BlockerSettings settings) {
    _settings = settings;
    _timer ??= Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _warned.clear();
  }

  Future<void> _check() async {
    if (!_settings.enabled) return;

    // 1. 프로세스 감지
    if (_settings.apps.isNotEmpty) {
      final processes = await _runningProcesses();
      for (final blocked in _settings.apps) {
        final needle = blocked.toLowerCase();
        final hit = processes.firstWhere(
          (p) => p.toLowerCase().contains(needle),
          orElse: () => '',
        );
        if (hit.isEmpty) continue;
        var killed = false;
        if (_settings.autoKill) {
          killed = await _killProcess(hit);
        }
        _notifyOnce(blocked, killed);
      }
    }

    // 2. 활성 창 제목으로 사이트 감지 (소프트 차단 — 경고만)
    if (_settings.sites.isNotEmpty) {
      final title = await _activeWindowTitle();
      if (title != null && title.isNotEmpty) {
        for (final site in _settings.sites) {
          if (title.toLowerCase().contains(site.toLowerCase())) {
            _notifyOnce(site, false);
          }
        }
      }
    }
  }

  void _notifyOnce(String target, bool killed) {
    // autoKill이면 앱을 다시 켤 때마다 경고, 아니면 세션당 1회
    if (!killed && _warned.contains(target)) return;
    _warned.add(target);
    onViolation?.call(target, killed);
  }

  // ---- 플랫폼별 프로세스 목록 ----
  Future<List<String>> _runningProcesses() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run(
          'tasklist',
          ['/fo', 'csv', '/nh'],
          runInShell: true,
        );
        return (result.stdout as String)
            .split('\n')
            .map((line) => line.split('","').first.replaceAll('"', '').trim())
            .where((name) => name.isNotEmpty)
            .toList();
      }
      // macOS / Linux
      final result = await Process.run('ps', ['-eo', 'comm=']);
      return (result.stdout as String)
          .split('\n')
          .map((line) => line.trim())
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ---- 플랫폼별 프로세스 종료 ----
  Future<bool> _killProcess(String processName) async {
    try {
      if (Platform.isWindows) {
        final image =
            processName.endsWith('.exe') ? processName : '$processName.exe';
        final result = await Process.run(
          'taskkill',
          ['/IM', image, '/F'],
          runInShell: true,
        );
        return result.exitCode == 0;
      }
      final result = await Process.run('pkill', ['-f', processName]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ---- 플랫폼별 활성 창 제목 ----
  Future<String?> _activeWindowTitle() async {
    try {
      if (Platform.isWindows) {
        const script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class W {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder t, int c);
}
"@
\$b = New-Object System.Text.StringBuilder 512
[void][W]::GetWindowText([W]::GetForegroundWindow(), \$b, 512)
\$b.ToString()
''';
        final result = await Process.run(
          'powershell',
          ['-NoProfile', '-Command', script],
        );
        return (result.stdout as String).trim();
      }
      if (Platform.isMacOS) {
        // 손쉬운 사용(Accessibility) 권한이 없으면 실패 → null 반환
        final result = await Process.run('osascript', [
          '-e',
          'tell application "System Events" to get title of front window of '
              '(first application process whose frontmost is true)',
        ]);
        return result.exitCode == 0
            ? (result.stdout as String).trim()
            : null;
      }
      if (Platform.isLinux) {
        // xdotool 설치되어 있을 때만 (X11)
        final result = await Process.run(
          'xdotool',
          ['getactivewindow', 'getwindowname'],
        );
        return result.exitCode == 0
            ? (result.stdout as String).trim()
            : null;
      }
    } catch (_) {
      // 도구 미설치/권한 없음 → 사이트 감지만 조용히 비활성
    }
    return null;
  }

  void dispose() => stop();
}
