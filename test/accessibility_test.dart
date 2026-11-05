// 5단계: 폰 새 화면 접근성 — 터치 크기, 눌리는 것의 라벨, 글자 대비
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:focus_one/core/app_theme.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/mobile/focus/focus_home.dart';
import 'package:focus_one/mobile/growth/growth_pages.dart';
import 'package:focus_one/mobile/growth/growth_tab.dart';
import 'package:focus_one/state/app_state.dart';

void main() {
  final pages = <String, Widget>{
    '집중 홈': const FocusHome(),
    '성장': const GrowthTab(),
    '목표': const GoalPage(),
    '연속일': const StreakPage(),
  };
  for (final scene in FocusScene.values) {
    for (final entry in pages.entries) {
      testWidgets('${scene.name} ${entry.key}', (tester) async {
        final handle = tester.ensureSemantics();
        final dir = Directory.systemTemp.createTempSync('fo');
        addTearDown(() {
          try {
            dir.deleteSync(recursive: true);
          } on FileSystemException {
            // 임시 폴더
          }
        });
        final st = AppState(LocalStore(File('${dir.path}/d.json')));
        st.setScene(scene);
        await tester.binding.setSurfaceSize(const Size(402, 874));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: st,
          child: MaterialApp(
            theme: AppTheme.of(scene),
            home: Scaffold(
                backgroundColor: scene.style.cardBg,
                body: SafeArea(child: entry.value)),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        st.dispose();
        handle.dispose();
      });
    }
  }
}
