// 세션 복구·저장 안전성 (P2): 앱이 꺼졌다 켜져도 기록·보상은 정확히 한 번.
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/models/task.dart';
import 'package:focus_one/state/app_state.dart';

void main() {
  late Directory dir;
  late File file;
  final t0 = DateTime(2026, 10, 11, 9);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('focusone');
    file = File('${dir.path}/data.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppState> boot(DateTime at) => withClock(Clock.fixed(at), () async {
        final s = AppState(LocalStore(file));
        await s.init();
        return s;
      });


  test('구버전(v1) JSON 그대로 로드', () async {
    file.writeAsStringSync(jsonEncode({
      'tasks': [
        {'id': 't1', 'title': '옛 작업', 'isDone': false, 'createdAt': t0.toIso8601String()}
      ],
      'sessions': [
        {'id': 's1', 'taskId': 't1', 'taskTitle': '옛 작업', 'minutes': 25, 'endedAt': t0.toIso8601String()}
      ],
    }));
    final data = await LocalStore(file).load();
    expect(data.tasks.single.title, '옛 작업');
    expect(data.sessions.single.outcome, SessionOutcome.completed);
    expect(data.sessions.single.startedAt, isNull); // 지어내지 않음
    expect(data.activeSession, isNull);
  });

  test('진행 중 종료 → 재실행 시 남은 시간 이어서', () async {
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () {
      a.addTask('보고서', setAsCurrent: true);
      a.startTimer();
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    a.dispose();

    final b = await boot(t0.add(const Duration(minutes: 5)));
    withClock(Clock.fixed(t0.add(const Duration(minutes: 5))), () {
      expect(b.isRunning, isTrue);
      expect(b.remainingSeconds, 20 * 60);
    });
    expect(b.sessions, isEmpty);
    b.dispose();
  });

  test('꺼진 사이 끝난 세션은 재실행 시 한 번만 완료 기록', () async {
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () {
      a.addTask('보고서', setAsCurrent: true);
      a.startTimer();
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    a.dispose();

    final later = t0.add(const Duration(hours: 1));
    final b = await boot(later);
    expect(b.sessions.length, 1);
    expect(b.sessions.single.outcome, SessionOutcome.completed);
    expect(b.sessions.single.focusedSec, 25 * 60);
    expect(b.activeSession, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    b.dispose();

    // 같은 파일로 또 켜도 중복 없음
    final c = await boot(later.add(const Duration(minutes: 1)));
    expect(c.sessions.length, 1);
    c.dispose();
  });

  test('일시정지 상태는 시간이 흘러도 그대로', () async {
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () {
      a.addTask('보고서', setAsCurrent: true);
      a.startTimer();
    });
    withClock(Clock.fixed(t0.add(const Duration(minutes: 10))), a.pauseTimer);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    a.dispose();

    final b = await boot(t0.add(const Duration(hours: 3)));
    withClock(Clock.fixed(t0.add(const Duration(hours: 3))), () {
      expect(b.isRunning, isFalse);
      expect(b.remainingSeconds, 15 * 60);
    });
    expect(b.sessions, isEmpty);
    b.dispose();
  });

  test('그만두기: 집중한 만큼 기록, 결과는 abandoned', () async {
    final a = await boot(t0);
    withClock(Clock.fixed(t0), () {
      a.addTask('보고서', setAsCurrent: true);
      a.startTimer();
    });
    withClock(Clock.fixed(t0.add(const Duration(minutes: 7))), a.abandonSession);
    expect(a.sessions.single.outcome, SessionOutcome.abandoned);
    expect(a.sessions.single.focusedSec, 7 * 60);
    expect(a.todaySessionCount, 0); // 보상·카운트 없음
    a.dispose();
  });

  test('본 파일이 깨지면 복구본(.bak)에서 읽음', () async {
    final store = LocalStore(file);
    await store.save(StoreData.empty());
    await store.save(const StoreData(tasks: [], inbox: [], sessions: [], soundVolume: 0.3));
    file.writeAsStringSync('{깨진 json');
    final data = await LocalStore(file).load();
    expect(data.soundVolume, 0.6); // .bak = 첫 번째 저장본
  });
}
