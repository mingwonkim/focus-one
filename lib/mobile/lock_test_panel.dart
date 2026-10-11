// lib/mobile/lock_test_panel.dart
// P1 기술 시험용 임시 화면 — P6 본구현 때 삭제.
import 'package:flutter/material.dart';

import '../services/focus_lock_service.dart';

class LockTestPanel extends StatefulWidget {
  const LockTestPanel({super.key});

  @override
  State<LockTestPanel> createState() => _LockTestPanelState();
}

class _LockTestPanelState extends State<LockTestPanel> {
  final _lock = FocusLockService();
  String _log = '';

  Future<void> _run(String label, Future<Object?> Function() f) async {
    try {
      final r = await f();
      setState(() => _log = '$label → $r\n$_log');
    } catch (e) {
      setState(() => _log = '$label → 오류 $e\n$_log');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('앱 잠금 기술 시험',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (final (label, f) in <(String, Future<Object?> Function())>[
          ('상태', () async => (await _lock.status()).toString()),
          ('1. 권한 요청', _lock.authorize),
          ('2. 잠글 앱 선택', _lock.pickApps),
          (
            '3. 15분 잠금 시작',
            () => _lock.start('test-${DateTime.now().millisecondsSinceEpoch}',
                DateTime.now().add(const Duration(minutes: 15, seconds: 5)))
          ),
          (
            '잠금 해제',
            () async {
              await _lock.stop();
              return 'ok';
            }
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton(
                onPressed: () => _run(label, f), child: Text(label)),
          ),
        const SizedBox(height: 12),
        Text(_log),
      ],
    );
  }
}
