// 꾸미기: 장면 구분 없는 풍경 하나, 모든 친구가 보이고 기본 친구 4종은 처음부터 고를 수 있다
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/mobile/scenery/scenery_tab.dart';
import 'package:focus_one/state/app_state.dart';

void main() {
  testWidgets('장면 선택 없이 친구 36종, 라떼멍을 놓을 수 있다', (tester) async {
    final dir = Directory.systemTemp.createTempSync('fo');
    final file = File('${dir.path}/d.json');
    await tester.runAsync(() => LocalStore(file).save(const StoreData(
          tasks: [],
          inbox: [],
          sessions: [],
        )));
    final st = AppState(LocalStore(file));
    await tester.runAsync(st.init);
    st.setScene(FocusScene.ocean);
    const size = Size(375, 6000);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: size),
      child: ChangeNotifierProvider.value(
        value: st,
        child: const MaterialApp(home: Scaffold(body: SceneryTab())),
      ),
    ));
    for (final label in ['바다', '일상', '숲', '밤']) {
      expect(find.text(label), findsNothing, reason: '장면 구분 없음');
    }
    await tester.tap(find.text('배치 바꾸기'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    expect(find.text('라떼멍'), findsOneWidget);
    expect(find.textContaining('옮기기'), findsNothing);
    expect(find.text('???'), findsNWidgets(32), reason: '못 만난 친구는 그림자로');

    await tester.tap(find.text('라떼멍'));
    await tester.pump();
    expect(find.text('빈 칸을 눌러 놓기'), findsOneWidget);
    st.dispose();
  });
}
