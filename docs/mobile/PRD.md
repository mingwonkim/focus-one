# FocusOne 모바일 v1 — PRD

## 타깃 · JTBD
- ADHD 성향 학생·직장인. 폰을 들면 딴짓으로 새는 사람.
- JTBD: "지금 이거 하나만" 정해 두고, 폰이 나를 방해하지 않게 잠근 채, 집중한 만큼 눈에 보이는 보상을 받는다. 딴생각은 한 줄 메모로 던지고 바로 복귀.

## 차별점 (Arctic Habit 대비, 심사 4.1 대응)
1. 홈 맨 위 **지금 할 일 하나** — 태그가 아니라 작업 단위로 집중(데스크탑 FocusOne과 동일 철학).
2. **딴생각 메모(인박스)** — 집중 중에도 한 줄로 던지고 복귀. 끝나면 할 일로 승격.
3. 장면 3종(숲·밤·바다)이 **소리 + 링 안 풍경 + 친구 + 풍경 꾸미기**를 모두 결정 — 한 앱 안에서 분위기 전환.
4. 밝은 파스텔 기본(밤만 다크). 데스크탑과 같은 브랜드·데이터 모델.

## 핵심 흐름
1. 홈: 지금 할 일(또는 태그만) → 시간 링 드래그(10~180분, 5분 단위) → 데려올 친구 선택 → 시작.
2. 진행: 링 줄어듦 + 링 안 친구가 점점 선명 + 장면 소리. (15분 이상이면) 앱 잠금. 딴생각 버튼 → 한 줄 메모.
3. 완료: 보상 시트(친구 획득 + 재화) → 풍경에 배치 또는 나중에. 휴식 제안.
4. 그만두기: 확인 → 기록은 남고 보상 없음.

## IA — 떠 있는 캡슐 탭바 4개
| 탭 | 내용 |
|---|---|
| 집중 | 홈 타이머(대기/진행/완료) |
| 풍경 | 장면별 풍경 + 친구 배치(격자) · 보관함 · 상점 |
| 기록 | 연속일·일/주/월/년·태그 분포·잔디·골든타임·세션 로그 · 도감 진입 |
| 할 일 | 태그 섹션별 할 일 + 인박스 |
설정은 홈 우상단. 시트: 소리, 태그, 친구 선택, 앱 잠금 설정.

## 지금 있는 데이터/API (lib/state/app_state.dart)
Task(id,title,isDone,createdAt,completedAt), BrainDumpItem, FocusSession(taskId,minutes,endedAt), BlockerSettings, scene, sound on/volume. 타이머는 1초 감소식 메모리 상태(저장 안 됨). LocalStore = JSON 파일 1개, 실패 시 조용히 무시.

## 추가 데이터 (계획 P2~P3)
Tag, Task.tagId, Session(id,startedAt,endedAt,focusedSec,tagId,taskId?,scene,companionId?,outcome), 진행 중 세션 스냅샷, Companion 카탈로그(장면당 4), owned, placements(풍경별 6×6), 재화, 스키마 버전.

## 제약
- 로그인·서버·광고·구독 없음. 데이터는 기기 로컬(백업은 v2).
- iOS 앱 잠금: Family Controls(.individual), DeviceActivity 최소 15분 → **15분 이상 세션만 잠금**. 배포 권한 Apple 승인 필요.
- Android 앱 잠금: AccessibilityService + Play 정책 선언·동의 화면.
- 데스크탑 빌드(macOS/Windows/Linux) 회귀 금지.

## 성공 지표
- 첫 세션 완료율, D7 재방문, 세션 평균 길이, 딴생각 메모 사용률.
- 품질: 앱 강제 종료·재부팅 후 중복 보상 0, 잠금 해제 누락 0, 크래시 0.
