너는 시니어 프로덕트 디자이너 겸 Flutter 데스크탑 UI 아키텍트다. 한국어로 답한다. 코드는 수정하지 말고 읽기만 해라.

대상: "FocusOne" Flutter 데스크탑 앱(macOS/Windows/Linux, 프레임리스 항상-위 미니 위젯). 웹은 이번 범위 아님.
먼저 읽을 것: docs/v2/PRD.md, docs/v2/refs/app-focus.md, lib/core/design_tokens.dart, lib/core/scene_decorations.dart, lib/features/mini/mini_widget_screen.dart, lib/features/mini/widgets/focus_ring.dart, lib/features/expanded/expanded_screen.dart, lib/features/expanded/widgets/task_list.dart, lib/features/expanded/widgets/inbox_list.dart, lib/features/capture/quick_capture_overlay.dart.

사용자 요구:
- 주 레퍼런스 Tiimo 집중 화면(밝은 파스텔, 굵은 링, 링 아래 큰 숫자, 검은 알약 버튼, 흰 둥근 카드 리스트+오른쪽 원형 체크)을 최대한 비슷하게.
- 링 안에는 우리 장면 일러스트(SceneDialPainter: 숲/달토끼/고래)를 넣는다 — 숲소리·파도소리 앰비언트가 우리 강점. 링 안 시간 텍스트는 빼고 일러스트를 가리지 않는다.
- 숲/밤/바다 3장면 유지. 장면별 accent 1개(작은 글자 대비 4.5:1), 파스텔 틴트 바탕(베이지 금지). 밤은 Tiimo 다크 느낌.
- 창 크기 고정: 미니 320×128, 확장 400×560, 퀵 캡처 400×180. 이 안에서 오버플로 없이.
- 정보 과밀 금지. 업계 표준 우선. 기존 기능(세션 길이 선택, 사운드 on/off·볼륨, 장면 전환, 인박스/차단 탭, 완료, 리셋, 휴식 건너뛰기, 패널 열기/접기)은 전부 유지.
- 새 패키지 없이 Flutter 기본 애니메이션으로 마이크로 인터랙션(누름 0.97 스케일, 장면 전환 크로스페이드, 링 진행 부드럽게). 일러스트는 코드 페인팅 유지 — 이미지 생성 에셋 없음.
- 토큰은 design_tokens.dart 의 SceneStyle/AppSpacing/AppRadius 에 추가·수정하는 방식.

산출물(마크다운 설계서 — 이대로 Opus가 구현한다, 2,500~4,000자):
1. 정보 구조: 미니/확장/인박스·차단 뷰/퀵 캡처 각각의 요소 순서와 픽셀 그리드(여백·폭).
2. 화면별 레이아웃·컴포넌트 명세(크기·간격·타이포 크기·굵기·상태: 대기/집중/일시정지/휴식/할 일 없음).
3. 브랜드 시스템: 장면 3종별 색 토큰(hex: 바탕, 카드, 링 진행/트랙, 링 안 원 배경, 텍스트 3단, 알약 버튼 bg/fg, 체크), 대비 확인, 타이포 스케일(시스템 글꼴), 반경·그림자.
4. 모션 명세: 트리거·속성·지속시간·커브.
5. 구현 순서(단계별)와 완료 기준.
