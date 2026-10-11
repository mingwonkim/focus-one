너는 시니어 프로덕트 디자이너 겸 Flutter 모바일 UI 아키텍트다. 한국어로 답한다. 코드는 수정하지 말고 읽기만 해라.

대상: "FocusOne" 모바일 앱(Flutter, iOS+Android). 같은 저장소의 데스크탑 앱(미니 위젯)과 같은 서비스로 보여야 한다.
먼저 읽을 것: docs/mobile/PRD.md, docs/mobile/refs/arctic-habit.md(주 레퍼런스 실측), docs/mobile/refs/mobbin.md, docs/v2/app-design-spec.md(데스크탑 v2 브랜드), lib/core/design_tokens.dart, lib/core/scene_decorations.dart, lib/features/mini/widgets/focus_ring.dart, lib/state/app_state.dart, ~/.claude/plans/zazzy-crunching-hammock.md(구현 계획·astra 리뷰 반영분).

사용자 요구:
- Arctic Habit 기능 거의 전부(타이머 10~180분 링 드래그, 완료 시 친구 획득, 풍경 꾸미기 6×6 격자, 보관함·도감·상점·재화, 통계 일/주/월/년·태그 분포·잔디·골든타임, 태그별 할 일, 앱 잠금, 집중 소리). 로그인·구독·광고는 없음.
- 레이아웃 패턴만 Arctic 참고, 색·링·장면 그림은 v2(숲·밤·바다 파스텔, 밤만 다크). Arctic을 픽셀 복제하지 말 것(심사 4.1). 차별점: 홈 맨 위 "지금 할 일 하나" + 딴생각 메모 버튼, 떠 있는 캡슐 탭바 4개(집중·풍경·기록·할 일), 장면이 소리·링·친구·풍경을 함께 결정.
- 업계 표준 우선, 정보 과밀 금지(칩 한 단어, 보조 문구 최소), 강조색 1개(작은 글자 4.5:1), 베이지 금지, 가로 카드 잘림 금지.
- 모션: Flutter 기본 애니메이션만(누름 0.97, 보상 팝+햅틱, 시트 드래그, 링 드래그 스냅 5분 햅틱, 친구 선명해지기), reduce-motion 대응.
- 친구 그림: 장면당 4종 = 12장(Higgsfield). 풍경 배경은 코드로 그림.
- iOS 앱 잠금은 15분 이상 세션만 가능(DeviceActivity 제약) — UI에 자연스럽게 반영.

사용 가능한 Higgsfield 이미지 모델(실제 목록, 이 중에서만): gpt_image_2_5(background=transparent 지원, quality low~max), gpt_image_2, nano_banana_pro, nano_banana_2, flux_2(pro/flex/max), flux_3_image, seedream_v5_pro(remove_bg 옵션), recraft_v4_1(vector), soul_location, z_image(시안용).

산출물(마크다운 설계서 — 이대로 Opus가 구현한다, 3,000~5,000자):
1. 정보 구조: 탭 4개·시트·전체화면 목록과 진입 경로, 390pt 기준 그리드(좌우 여백·열·SafeArea), 작은 화면(SE 375×667)·큰 화면 대응.
2. 화면별 레이아웃·컴포넌트 명세(크기·간격·타이포·상태): 집중 홈(대기/진행/일시정지/완료/할 일 없음), 보상 시트, 친구 선택 시트, 소리 시트, 태그 시트, 딴생각 메모 시트, 풍경(보기/편집), 보관함, 도감, 상점, 기록, 할 일, 앱 잠금 안내·설정, 설정, 첫 실행(로그인 없이 바로 홈, 코치마크 최대 3).
3. 브랜드 시스템: 장면 3종 색 토큰(hex, 대비 확인) — 데스크탑 SceneStyle과 공유 가능한 이름으로, 모바일 추가 토큰(탭바·시트·카드), 타이포 스케일(iOS 시스템 글꼴 / Android Pretendard 여부 판단), 반경·그림자.
4. 모션 명세: 트리거·속성·시간·커브·햅틱 종류.
5. Higgsfield 에셋 12장: 친구 이름(한국어)·장면·해금 조건·프롬프트(영문, 스타일 통일 문구 포함)·모델·비율·배경 처리.
6. 재화·해금 경제: 재화 이름, 분당 획득량, 친구 해금 조건, 상점 가격 — 단순하게.
7. 구현 순서와 완료 기준(계획 P4~P7에 맞춰).
