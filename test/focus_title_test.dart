import 'package:flutter_test/flutter_test.dart';
import 'package:focus_one/models/focus_title.dart';

void main() {
  test('문턱 경계', () {
    expect(FocusTitle.of(0), FocusTitle.seed);
    expect(FocusTitle.of(29), FocusTitle.seed);
    expect(FocusTitle.of(30), FocusTitle.sprout);
    expect(FocusTitle.of(29999), FocusTitle.deep);
    expect(FocusTitle.of(30000), FocusTitle.master);
    expect(FocusTitle.of(999999), FocusTitle.master);
  });

  test('문턱은 단조 증가, 마스터는 500시간', () {
    for (var i = 1; i < FocusTitle.values.length; i++) {
      expect(FocusTitle.values[i].minMinutes,
          greaterThan(FocusTitle.values[i - 1].minMinutes));
    }
    expect(FocusTitle.master.minMinutes, 500 * 60);
  });

  test('다음 칭호·남은 분·진행도', () {
    expect(FocusTitle.seed.next, FocusTitle.sprout);
    expect(FocusTitle.seed.remaining(10), 20);
    expect(FocusTitle.sprout.progress(90), 0.5); // 30~150 중 90
    expect(FocusTitle.master.next, isNull);
    expect(FocusTitle.master.remaining(40000), 0);
    expect(FocusTitle.master.progress(40000), 1);
  });
}
