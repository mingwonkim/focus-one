// 꾸미기 2안 비교: A 그라데이션 배치 / B 동물원 자리. 한 장으로 (macOS 전용). CI 대상 아님.
// 실행: flutter test tool/preview/scenery_compare_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:focus_one/core/app_theme.dart';
import 'package:focus_one/core/design_tokens.dart';
import 'package:focus_one/data/local_store.dart';
import 'package:focus_one/mobile/scenery/scenery_tab.dart';
import 'package:focus_one/models/collection.dart';
import 'package:focus_one/state/app_state.dart';

import 'capture_test.dart' show loadFont;

const out = String.fromEnvironment('OUT', defaultValue: '/tmp');

const _sample = [
  Placement('fawn', 1, 1),
  Placement('tree', 3, 0),
  Placement('rabbit', 4, 1),
  Placement('whale', 0, 3),
  Placement('bench', 2, 3),
  Placement('puppy', 4, 3),
  Placement('squirrel', 1, 4),
  Placement('grass', 3, 5),
];

const _zoo = [
  'fawn',
  'rabbit',
  'whale',
  'puppy',
  'squirrel',
  'owl',
  'turtle',
  null,
  null,
  null,
  null,
  null,
];

void main() {
  testWidgets('compare', (tester) async {
    await tester.runAsync(loadFont);
    final dir = Directory.systemTemp.createTempSync('fo');
    final file = File('${dir.path}/d.json');
    await tester.runAsync(() => LocalStore(file).save(const StoreData(
          tasks: [],
          inbox: [],
          sessions: [],
          progress: Progress(
            drops: 340,
            owned: {
              'squirrel': 1,
              'owl': 1,
              'turtle': 1,
              'tree': 1,
              'bench': 1,
              'grass': 1
            },
            placements: {Progress.boardKey: _sample},
          ),
        )));
    final st = AppState(LocalStore(file));
    await tester.runAsync(st.init);
    const size = Size(900, 960);
    await tester.binding.setSurfaceSize(size);
    const phone = Size(402, 874);
    final key = GlobalKey();
    Widget screen(String label, Widget child) => Column(children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2622))),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: SizedBox.fromSize(
              size: phone,
              child: MediaQuery(
                data: const MediaQueryData(size: phone),
                child: child,
              ),
            ),
          ),
        ]);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: st,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.of(st.scene).copyWith(
            textTheme: AppTheme.of(st.scene)
                .textTheme
                .apply(fontFamily: 'AppleGothic')),
        home: RepaintBoundary(
          key: key,
          child: DefaultTextStyle.merge(
            style: const TextStyle(fontFamily: 'AppleGothic'),
            child: Scaffold(
              backgroundColor: const Color(0xFFD9DEDB),
              body: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      screen(
                          'A  그라데이션 배치',
                          Scaffold(
                              backgroundColor: st.scene.style.cardBg,
                              body: const Padding(
                                padding: EdgeInsets.only(top: 44),
                                child: SceneryTab(),
                              ))),
                      screen('B  동물원', const _ZooMock()),
                    ]),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 900)));
    await tester.pump();
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final d = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$out/scenery-compare.png').writeAsBytesSync(d!.buffer.asUint8List());
    });
    await tester.binding.setSurfaceSize(null);
    st.dispose();
  });
}

class _ZooMock extends StatelessWidget {
  const _ZooMock();

  @override
  Widget build(BuildContext context) {
    final style = FocusScene.forest.style;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCEFD6), Color(0xFFB9DDB0)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 14),
      child: Column(children: [
        Row(children: [
          Text('꾸미기',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: style.textStrong)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: style.rowBg, borderRadius: BorderRadius.circular(99)),
            child: Text('💧 340',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: style.textStrong)),
          ),
        ]),
        const SizedBox(height: 10),
        const _Sign(),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.88,
            children: [for (final id in _zoo) _Pen(id: id)],
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          for (final (i, label) in const ['보관함', '도감', '상점'].indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: style.rowBg,
                    borderRadius: BorderRadius.circular(99)),
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: style.textStrong)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _Sign extends StatelessWidget {
  const _Sign();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF9A6B43),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF714A2B), width: 2),
        ),
        child: const Text('나의 동물원 · 7/36',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFF4E2))),
      );
}

class _Pen extends StatelessWidget {
  const _Pen({required this.id});
  final String? id;

  @override
  Widget build(BuildContext context) {
    final c = Companion.byId(id);
    return CustomPaint(
      painter: _PenPainter(filled: c != null),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Column(children: [
          Expanded(
            child: c != null
                ? Image.asset(c.asset)
                : const Center(
                    child: Icon(Icons.add_rounded,
                        size: 30, color: Color(0xFFA08A63))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c != null
                  ? const Color(0xFF9A6B43)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(c?.name ?? '빈 자리',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c != null
                        ? const Color(0xFFFFF4E2)
                        : const Color(0xFF8D7954))),
          ),
        ]),
      ),
    );
  }
}

/// 위에서 본 우리: 흙 바닥 + 나무 울타리
class _PenPainter extends CustomPainter {
  const _PenPainter({required this.filled});
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(3), const Radius.circular(14));
    canvas.drawRRect(
        r,
        Paint()
          ..color = filled ? const Color(0xFFF5E8C8) : const Color(0x88F5E8C8));
    const wood = Color(0xFF9A6B43);
    final rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = wood.withValues(alpha: filled ? 1 : 0.45);
    canvas.drawRRect(r, rail);
    final post = Paint()..color = wood.withValues(alpha: filled ? 1 : 0.45);
    const n = 5;
    for (var i = 0; i < n; i++) {
      final x = 12 + (size.width - 24) * i / (n - 1);
      for (final y in [3.0, size.height - 3]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, y), width: 6, height: 11),
                const Radius.circular(2)),
            post);
      }
    }
    for (var i = 1; i < 4; i++) {
      final y = 12 + (size.height - 24) * i / 4;
      for (final x in [3.0, size.width - 3]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, y), width: 11, height: 6),
                const Radius.circular(2)),
            post);
      }
    }
  }

  @override
  bool shouldRepaint(_PenPainter o) => o.filled != filled;
}
