// lib/models/focus_title.dart
// 칭호: 끝까지 완료한 집중의 누적 분으로 정한다(비상 탈출로 내려가지 않음).
// 숲 → 밤 → 바다 → 마스터 여정. 서버 명예의 전당도 같은 문턱(서버가 준 누적 분)으로 계산.

enum FocusTitle {
  seed('씨앗', 0),
  sprout('새싹', 30),
  leaf('잎새', 150),
  tree('나무', 450),
  keeper('숲지기', 1200),
  moonlight('달빛', 2400),
  stars('별무리', 4800),
  wave('파도', 9000),
  deep('심해', 15000),
  master('마스터', 30000);

  const FocusTitle(this.label, this.minMinutes);

  final String label;
  final int minMinutes;

  static FocusTitle of(int minutes) =>
      values.lastWhere((t) => minutes >= t.minMinutes);

  FocusTitle? get next => this == master ? null : values[index + 1];

  /// 다음 칭호까지 남은 분 (마스터면 0)
  int remaining(int minutes) =>
      next == null ? 0 : (next!.minMinutes - minutes).clamp(0, next!.minMinutes);

  /// 이번 칭호 구간 안 진행도 0~1 (마스터면 1)
  double progress(int minutes) => next == null
      ? 1
      : ((minutes - minMinutes) / (next!.minMinutes - minMinutes)).clamp(0, 1);
}
