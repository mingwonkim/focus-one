# FocusOne v2 — PRD (앱 UI/UX 리디자인)

## 타깃·JTBD
- ADHD 성향 직장인·학생. "지금 이거 하나만" 하고 싶은데 작업 전환·딴생각·시간 감각 상실로 무너진다.
- JTBD: 화면 구석에 현재 작업 1개와 줄어드는 시간을 띄워 두고, 딴생각은 단축키로 던진 뒤 바로 복귀.

## 플랫폼·제약 (실제)
- Flutter 데스크탑(macOS/Windows/Linux), 프레임리스·항상 위 창. 계정·서버·DB 없음, LocalStore JSON 1파일.
- 창 크기 고정: 미니 320×128, 확장 400×560, 퀵 캡처 400×180. (window_service가 크기 전환)
- 색·크기는 `lib/core/design_tokens.dart`, 장면 값은 `FocusScene`/`SceneStyle` 에만.
- 글꼴: 시스템 글꼴(macOS SF / Windows 맑은 고딕 계열). 외부 폰트 없음.
- 모션: Flutter 기본(AnimatedContainer/TweenAnimationBuilder/AnimatedSwitcher). 추가 패키지 지양.

## 핵심 흐름
1. 확장 패널에서 할 일 선택 → ▶ 집중 시작 → 미니 위젯으로 접어 두기.
2. 집중 중 링이 줄어듦(Time Timer 방식) + 장면 앰비언트 사운드(숲소리·뻐꾸기/바람·파도).
3. 끝나면 완료 알림 → 휴식 → 다음 세션. 완료 수는 푸터 "오늘 심은 나무 🌲 n그루"류로 보상.
4. 딴생각 → `Ctrl+Shift+Space` 퀵 캡처 → 인박스 → 나중에 할 일로 승격.

## 화면 (IA)
| 화면 | 내용 |
|---|---|
| 미니 위젯 | 링(장면 일러스트 내장) · 라벨 · 현재 작업 · 시간 · 재생 버튼 · 패널 열기 |
| 확장 패널 | 헤더(타이틀·세션 길이·사운드·접기·장면 전환) → 큰 링 → 시간 → 컨트롤 → 탭(오늘의 작업/인박스/차단) → 리스트 → 푸터 통계 |
| 인박스/차단 뷰 | 큰 링 대신 소형 타이머 줄 |
| 퀵 캡처 | 한 줄 입력 → Enter 닫힘 |

## 지금 있는 데이터/API (AppState)
currentTask, pendingTasks, todayDoneTasks, sessionCountFor, inbox, progress(1→0), remainingSeconds, totalSeconds, isRunning, phase(focus/breakTime), scene, soundEnabled/Volume, todaySessionCount, todayFocusMinutes, streakDays.
액션: start/pause/stopTimer, skipBreak, completeCurrentTask, selectTask, addTask, deleteTask, setDurationMinutes(5/15/25/45), setScene, setSound*.

## 디자인 방향 (사용자 확정 2026-10-08)
- 주 레퍼런스 **Tiimo 집중 화면**(Mobbin ffeedfca…, 다크 fef7e27a…, 목록 2e03a5b5…).
- **링 안에는 우리 장면 일러스트(숲/달토끼/고래 — SceneDialPainter)** 를 넣는다. 사운드 장면이 우리 강점.
- 굵은 파스텔 링, 시간은 링 아래 큰 숫자, 검은(장면 진한색) 알약 버튼, 흰 둥근 카드 리스트 + 오른쪽 원형 체크.
- 숲/밤/바다 3장면 유지(밤 = Tiimo 다크 버전 느낌).

## 성공 기준
- 3장면 × 미니/확장/인박스/차단 렌더 오버플로 0 (`flutter test`), `flutter analyze` 0 이슈.
- 링 안 장면 일러스트가 미니(88)·확장에서 모두 식별 가능.
- 레퍼런스 대비 레이아웃 위계(제목→링→시간→컨트롤) 동일.
