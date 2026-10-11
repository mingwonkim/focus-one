// lib/mobile/records/records_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../state/stats.dart';
import '../focus/sheets.dart' show tagColor;

enum _Period { day, week, month, year }

/// 기록 탭 (spec §2): 연속일 → 일/주/월/년·기간 이동 → 시간/횟수 → 막대 → 태그 → 잔디 → 골든타임 → 세션
class RecordsTab extends StatefulWidget {
  const RecordsTab({super.key});

  @override
  State<RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<RecordsTab> {
  _Period _period = _Period.week;
  int _offset = 0; // 0 = 이번 기간, -1 = 이전…

  (DateTime, DateTime) _range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _Period.day:
        final d = DateTime(today.year, today.month, today.day + _offset);
        return (d, DateTime(d.year, d.month, d.day + 1));
      case _Period.week:
        final monday = DateTime(today.year, today.month,
            today.day - (today.weekday - 1) + 7 * _offset);
        return (monday, DateTime(monday.year, monday.month, monday.day + 7));
      case _Period.month:
        final m = DateTime(today.year, today.month + _offset);
        return (m, DateTime(m.year, m.month + 1));
      case _Period.year:
        final y = DateTime(today.year + _offset);
        return (y, DateTime(y.year + 1));
    }
  }

  String _label((DateTime, DateTime) r) {
    final (a, b) = r;
    return switch (_period) {
      _Period.day => '${a.month}월 ${a.day}일',
      _Period.week =>
        '${a.month}.${a.day} – ${b.subtract(const Duration(days: 1)).month}.${b.subtract(const Duration(days: 1)).day}',
      _Period.month => '${a.year}년 ${a.month}월',
      _Period.year => '${a.year}년',
    };
  }

  (List<int>, List<String>) _bars(FocusStats st, (DateTime, DateTime) r) {
    final (a, b) = r;
    return switch (_period) {
      _Period.day => (
          st.hours(a),
          [for (var h = 0; h < 24; h++) h % 6 == 0 ? '$h' : '']
        ),
      _Period.week => (
          st.range(a, 7),
          const ['월', '화', '수', '목', '금', '토', '일']
        ),
      _Period.month => (
          st.range(a, b.difference(a).inDays),
          [
            for (var d = 1; d <= b.difference(a).inDays; d++)
              d == 1 || d % 7 == 0 ? '$d' : ''
          ]
        ),
      _Period.year => (
          st.months(a.year),
          [for (var m = 1; m <= 12; m++) m % 3 == 1 ? '$m월' : '']
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final style = s.scene.style;
    final now = DateTime.now();
    final st = FocusStats(s.sessions);
    final r = _range(now);
    final (bars, labels) = _bars(st, r);
    final total = bars.fold(0, (a, b) => a + b);
    final byTag = st.byTag(r.$1, r.$2);
    final golden = st.goldenHours(now);
    final recent = s.sessions.reversed.take(20).toList();

    Widget card(Widget child, {EdgeInsets? padding}) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: style.rowBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.card(style.rowShadow),
          ),
          child: child,
        );
    TextStyle label() => TextStyle(fontSize: 13, color: style.textMuted);
    TextStyle value() => TextStyle(
        fontSize: 22, fontWeight: FontWeight.w700, color: style.textStrong);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          MobileSize.gutter, 8, MobileSize.gutter, MobileSize.tabBar + 40),
      children: [
        Text('기록',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: style.textStrong)),
        const SizedBox(height: 16),
        // 연속일 + 최근 7일 점
        card(Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('연속', style: label()),
            Text('${st.streak(now)}일', style: value()),
          ]),
          const Spacer(),
          for (final sec
              in st.range(DateTime(now.year, now.month, now.day - 6), 7))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sec >= 60 ? style.ringProgress : style.divider,
                ),
              ),
            ),
        ])),
        // 기간 선택
        SegmentedButton<_Period>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: _Period.day, label: Text('일')),
            ButtonSegment(value: _Period.week, label: Text('주')),
            ButtonSegment(value: _Period.month, label: Text('월')),
            ButtonSegment(value: _Period.year, label: Text('년')),
          ],
          selected: {_period},
          onSelectionChanged: (v) => setState(() {
            _period = v.first;
            _offset = 0;
          }),
        ),
        Row(children: [
          IconButton(
              tooltip: '이전',
              icon: Icon(Icons.chevron_left_rounded, color: style.textMuted),
              onPressed: () => setState(() => _offset--)),
          Expanded(
            child: Text(_label(r),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: style.textStrong)),
          ),
          IconButton(
              tooltip: '다음',
              icon: Icon(Icons.chevron_right_rounded,
                  color: _offset < 0 ? style.textMuted : style.divider),
              onPressed: _offset < 0 ? () => setState(() => _offset++) : null),
        ]),
        Row(children: [
          Expanded(
              child: card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('집중 시간', style: label()),
                Text(_hm(total), style: value()),
              ]))),
          const SizedBox(width: 12),
          Expanded(
              child: card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('완료', style: label()),
                Text('${st.completedCount(r.$1, r.$2)}회', style: value()),
              ]))),
        ]),
        card(SizedBox(
          height: 160,
          child: total == 0
              ? Center(child: Text('기록 없음', style: label()))
              : CustomPaint(
                  painter: _BarsPainter(bars, labels, style.ringProgress,
                      style.divider, style.textMuted)),
        )),
        if (byTag.isNotEmpty)
          card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('태그별', style: label()),
            const SizedBox(height: 12),
            for (final e
                in (byTag.entries.toList()..sort((a, b) => b.value - a.value)))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tagColor(
                          style,
                          s.tags
                                  .where((t) => t.id == e.key)
                                  .firstOrNull
                                  ?.colorIndex ??
                              4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        s.tags.where((t) => t.id == e.key).firstOrNull?.name ??
                            (e.key.isEmpty ? '태그 없음' : '삭제된 태그'),
                        style:
                            TextStyle(fontSize: 14, color: style.textStrong)),
                  ),
                  Text(_hm(e.value),
                      style: TextStyle(fontSize: 14, color: style.textMuted)),
                ]),
              ),
          ])),
        card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('6개월 집중 잔디', style: label()),
          const SizedBox(height: 12),
          _Heatmap(data: st.heatmap(now), style: style),
        ])),
        card(Row(children: [
          Text('골든타임', style: label()),
          const Spacer(),
          Text(
            golden.isEmpty ? '아직 몰라요' : golden.map((h) => '$h시').join(' · '),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: style.textStrong),
          ),
        ])),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('최근 세션', style: label()),
          const SizedBox(height: 8),
          for (final x in recent)
            card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              Row(children: [
                Expanded(
                  child: Text(
                    x.taskTitle.isEmpty ? '집중' : x.taskTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: style.textStrong),
                  ),
                ),
                Text(
                  '${x.endedAt.month}.${x.endedAt.day} · ${_hm(x.focusedSec ?? x.minutes * 60)}'
                  '${x.outcome == SessionOutcome.completed ? '' : ' · 중단'}',
                  style: TextStyle(fontSize: 13, color: style.textMuted),
                ),
              ]),
            ),
        ],
      ],
    );
  }

  static String _hm(int sec) {
    final m = sec ~/ 60;
    return m >= 60 ? '${m ~/ 60}시간 ${m % 60}분' : '$m분';
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.values, this.labels, this.color, this.track, this.text);
  final List<int> values;
  final List<String> labels;
  final Color color, track, text;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 18.0;
    final maxV = values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final w = size.width / values.length;
    final barW = (w * 0.6).clamp(2.0, 24.0);
    final h = size.height - labelH;
    for (var i = 0; i < values.length; i++) {
      final x = i * w + (w - barW) / 2;
      final bh = values[i] / maxV * h;
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, h - bh.clamp(2.0, h), barW, bh.clamp(2.0, h)),
          Radius.circular(barW / 2));
      canvas.drawRRect(r, Paint()..color = values[i] == 0 ? track : color);
      if (labels[i].isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
              text: labels[i], style: TextStyle(fontSize: 11, color: text)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(i * w + w / 2 - tp.width / 2, h + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter o) => o.values != values || o.color != color;
}

/// 26주 × 7일 격자, 명도 4단계
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.data, required this.style});
  final Map<DateTime, int> data;
  final SceneStyle style;

  @override
  Widget build(BuildContext context) {
    final days = data.entries.toList();
    final weeks = (days.length / 7).ceil();
    return LayoutBuilder(builder: (_, c) {
      final cell = (c.maxWidth - (weeks - 1) * 2) / weeks;
      return SizedBox(
        height: cell * 7 + 12,
        child: Row(children: [
          for (var w = 0; w < weeks; w++) ...[
            if (w > 0) const SizedBox(width: 2),
            Column(children: [
              for (var d = 0; d < 7; d++) ...[
                if (d > 0) const SizedBox(height: 2),
                Container(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: () {
                      final i = w * 7 + d;
                      final lv = i < days.length ? days[i].value : 0;
                      return lv == 0
                          ? style.divider
                          : Color.lerp(
                              style.divider, style.ringProgress, lv / 4)!;
                    }(),
                  ),
                ),
              ],
            ]),
          ],
        ]),
      );
    });
  }
}
