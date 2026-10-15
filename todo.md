# FocusOne todo

## 2026-07-14
- [x] macOS 다운로드 차단(Gatekeeper) 해결 — CI에 ad-hoc 서명 추가 + README에 xattr 안내 + 로컬 빌드해 /Applications/FocusOne.app 설치
- [x] 숲/밤/바다 3개 장면 모드 (테마 색 전환, 확장 패널 상단 아이콘으로 선택, 저장됨)
- [x] 장면별 앰비언트 사운드 (숲소리/뻐꾸기+바람/파도, 합성 WAV 40초 루프, 집중 중에만 재생)
- [x] 디자인을 바탕화면 시안(.dc.html 3종)과 동일하게 재구현 — 미니 320×128 / 확장 400×560, 장면 다이얼·뱃지·불릿·푸터 통계 전부 시안 값 사용
- [x] UI 편의성 개선 — 다이얼↔컨트롤 세로 간격 확대, 인박스/차단 뷰에서 큰 다이얼을 소형 타이머 줄로 접어 내용 공간 ~3배 확보, 탭 터치 영역 확대
- [x] 사운드 on/off + 볼륨 조절 — 확장 패널 헤더 스피커 아이콘 → 팝업(토글+슬라이더), 설정 저장됨
- [x] 커밋 + 푸시 완료 (0cd61d9, main)

## 2026-10-08 — 앱 UI/UX v2 (design-pipeline, design-v2 브랜치)
- [x] Mobbin 후보 제시 → 사용자 A안(Tiimo) + 링 안 장면 아이콘 선택
- [x] PRD·레퍼런스·astra 설계서 (docs/v2/)
- [x] 구현: 토큰·굵은 링+장면 일러스트·미니·확장·소형 타이머·작업 카드(원형 체크)·인박스·퀵 캡처·모션 — analyze 0, test 3/3 통과
- [x] 미리보기 PNG 3장면×미니/확장 생성 (tool/preview)
- [x] 사용자 확정 → main 머지·푸시
- [ ] 실제 macOS 앱 실행 확인 (창 드래그·팝업 메뉴·우클릭 삭제)

## 2026-10-08 — 포트폴리오 미디어
- [x] 스크린샷 2장(미니·확장, 투명 PNG 3x) + 데모 영상 1920×1080 13.7초 → ~/Desktop/focusone-portfolio/
- [x] 렌더러 tool/media/media_test.dart (타임랩스·사운드 재생 표시, 소리 없음)

## 2026-10-08 — 앱 아이콘
- [x] 코드 렌더 4안 + Higgsfield 시안 8장 비교 → 사용자 H3(바다·고래) 선택 (크레딧 6.5 사용, 잔액 30.18)
- [x] macOS/Windows/Linux(.deb)/트레이 아이콘 생성 + tool/apply_icons.sh + CI 적용, 로컬 macOS 릴리즈 빌드에서 AppIcon 확인

## 2026-10-11 — 모바일(iOS+Android) v1 (브랜치 mobile-v1, 계획 ~/.claude/plans/zazzy-crunching-hammock.md)
- [x] P0 레퍼런스: Arctic Habit 실측(iPhone 미러링, 10분 세션 완료까지) + Mobbin + PRD + astra 설계서 → docs/mobile/
- [ ] P1 플랫폼 추가·셸 분리 + 차단 기술 시험(iOS 15분 shield, Android 접근성) + Family Controls 배포 권한 신청
  - [x] ios/android 추가 + 폰 셸(탭 4개) — iOS 시뮬(iPhone 17 Pro)·Android 에뮬(focusone-design) 실행 확인
  - [x] 아이폰 실기기 등록·서명·설치 (팀 QZ366AK4NB), FocusLock+FocusMonitor 확장 탑재
  - [x] 차단 기술 시험: 아이폰 실기기에서 잠금 동작 확인 (사용자, 2026-10-11) — 앱 종료 후 자동 해제는 P6에서 재확인
  - [x] Family Controls 배포 권한 신청 제출 (2026-10-11, Apple 회신 대기)
- [x] P2 저장 안전성 + 세션 복구·보상 1회 확정 — 시각 기준 타이머, 진행 세션 저장, .bak 복구, 테스트 6개
- [x] P3 데이터 모델(태그·친구·배치·재화) + 통계 — Progress 묶음 저장(schema 3), FocusStats(자정 분할·잔디·골든타임), 테스트 9개
- [x] P4 집중 홈 1장 → 사용자 검토 → 할 일·기록·인박스·알림 (astra 리뷰 1 12건 반영, 잔디 → 장면색 집중 달력) — 소리 선택 시트는 P7
- [x] P5 풍경(6×6 꾸미기)·보관함·도감·상점 + 친구 12종·장식 9종(codex 이미지 생성) + 집중 소리 시트(빗소리·백색·갈색 합성)
- [ ] P6 Deep Focus 본구현
  - [x] 정식 잠금 화면(안내·동의·권한·앱 선택·설정), 세션 연동(재생=잠금, 일시정지·종료=해제)
  - [x] Android 접근성 잠금 — 에뮬레이터에서 차단·만료 후 미차단 확인
  - [x] 아이폰 실기기: 정식 화면 잠금·앱 종료 후에도 유지 확인(10/11), 자동 해제는 사용자 확인 완료
  - [ ] Android 실기기 확인, Play 접근성 선언·시연 영상(출시 전)
- [x] 실사용 피드백 1 (2026-10-11): 폰 일시정지 제거, 화면 꺼져도 소리(just_audio·백그라운드 오디오), Mixkit 원음 11개로 교체 + 장면별 상황 소리 (docs/mobile/sounds.md)
  - [ ] 아이폰에서 화면 끔·반복 이음새 확인
  - [x] 그만두기 막기: 시작 10초 안에만 취소, 이후엔 물방울로 비상 탈출(남은 1분당 2개, 보상 없음)
  - [x] 도서관·기차·모닥불 Freesound CC0로 교체, 백색·갈색 음량 −20 LUFS로 맞춤
- [x] 랭킹 (2026-10-11): Supabase focusone(서울) 익명 계정+닉네임, 점수 = 모은 물방울 − 비상 탈출, 하루 +720 상한·경과 분 검증, 이번 주/누적, 나가기. 시뮬 참여·나가기 확인
- [x] 풍경 탭 → '꾸미기' (탭 안 버튼은 '배치 바꾸기')
- [x] 소리 시트 장면별 정리: 빗소리→숲, 바람→밤, 백색·갈색만 '집중 소음' 공통. 폰 밤 아이콘 별(+) → 달
- [ ] 아이폰에 최신 빌드 설치 (랭킹·꾸미기 탭 포함) → 실기기 랭킹 참여 확인
- [x] 앱 이름 FocusOne → Tocko → **Fokko** (2026-10-12, 보이는 이름·Android ID com.looinlabs.fokko·사이트 /fokko·ASC 이름. iOS 번들 ID 유지)
- [x] Android applicationId·패키지 → com.looinlabs.tocko (debug APK 빌드 확인)
- [x] 지원 https://looinlabs.com/tocko/ · 개인정보 https://looinlabs.com/tocko/privacy 배포 (랭킹 수집 항목 포함)
- [x] App Store Connect 앱 등록 (사용자) — app id 6821653231
- [x] ASC API 키 (~/.config/fokko/asc.env, 저장소 밖) + tool/asc*.py: 문구·카테고리·연령등급·무료·175개국·저작권·버전 1.0.0 반영
- [x] 심사 연락처·메모 (appStoreReviewDetail, API)
- [x] 앱 개인정보 게시 · Apple Silicon Mac 사용 가능 끔 (웹)
- [x] 스토어 스크린샷 6.9" 5장 업로드 (tool/media/seed_test.dart 예시 데이터 → Pro Max 시뮬)
- [x] iPad 대응 (배율 짧은 변/640 최대 1.6, 가로 두 칸) + iPad 13" 스크린샷 5장 — 심사가 iPad 스크린샷 요구
- [x] 빌드 3 업로드(Xcode Organizer — CLI 서명은 'No Accounts'로 실패) → 버전 연결 → 심사 제출 (2026-10-12 WAITING_FOR_REVIEW, 자동 출시)
- [x] 휴식 남은 시간: iOS Live Activity(Dynamic Island·잠금 화면, BreakActivity 확장) + Android 카운트다운 알림 — 시뮬 확인
- [x] 1.0 거부(10/14, 2.5.1 자동 검사: Family Controls 권한 없이 제출) — App ID에 FAMILY_CONTROLS_DISTRIBUTION 승인돼 있음. 빌드 4(휴식 Live Activity 포함)를 Organizer Custom→Export로 IPA 만들어 family-controls 포함 확인 후 altool 업로드
- [x] 빌드 4 버전 연결 → 재제출 (10/15 00:56, WAITING_FOR_REVIEW). API PATCH submitted=true는 "not ready"로 실패 → ASC 웹 "심사 업데이트"→"앱 심사에 다시 제출"로 해결
- [ ] 1.0 2차 거부(10/15, 2.5.4 백그라운드 오디오 재생 안 들림) → astra 검토 반영, 빌드 5 업로드
  - [x] 소리: 끊김(전화·알림 등) 뒤 자동 재개, 로딩 직렬화·실패 재시도, 음량 0이면 정지 (실사용 화면 꺼짐 끊김 원인)
  - [x] 랭킹: 닉네임 자유 입력 → 단어 조합 자동 생성(UGC 회피), 나가기 = 익명 계정 삭제, 개인정보 처리방침 링크
  - [x] Live Activity: 앱 첫 동기화에서 남은 표시 정리
  - [x] 심사 메모 갱신(ASC·store.md)
  - [x] supabase db push (사용자 실행 10/16) — 익명 가입→leave_ranking→user_not_found 확인
  - [ ] (사용자) 실기기 증빙 영상: 소리 선택→시작→홈→잠금, 소리 계속 (외부 카메라로 잠금 화면)
  - [x] 빌드 5 버전 연결, 아이폰 설치
  - [ ] 해결 센터 답장(영상 첨부) → 재제출
- [ ] Android 휴식 알림 실기기 확인
- [ ] P7 모션 GIF·최종 미리보기 → 사용자 확정 → main 머지
- [ ] Android 출시: Play **조직 계정**(develop@looinlabs.com)으로 (2026-10-13 결정, 개인 계정 14일 테스트 대신)
  - [x] 서명 AAB 빌드 (업로드 키 CN=FocusOne, android/key.properties → ~/.config/focusone)
  - [x] 주소: 비상주 사무실 안 함 — 하루전(개인 계정, 인앱 구매)에 이미 공개돼 있음
  - [x] D-U-N-S 신청 제출 (2026-10-13, Apple duns-lookup 무료, 사업자 주소) → 발급 1~2주 대기, 안내 메일 develop@looinlabs.com
  - [ ] Play 조직 계정 가입($25 사용자 결제) → 서비스 계정 API 키 ~/.config/fokko/
  - [ ] Play 스토어 자료(문구·스크린샷 1080×1920·그래픽 1024×500·아이콘 512)·접근성 선언·시연 영상
  - [ ] 첫 AAB 업로드 → 심사 제출
- [ ] iOS 출시: Family Controls 배포 권한 승인 대기(10/11 신청) → 아카이브 → TestFlight → 심사

## 다음 세션
- [x] GitHub Actions 빌드 통과 확인 — 실패는 10/07 미사용 import 1회(다음 커밋에서 해결), 이후 main 4회 연속 성공
- [x] GitHub Actions에서 아이콘 단계(Windows bash·.deb Icon) 통과 확인 — 66f0fb8 성공
- [ ] (보류) 주간 랭킹 상위 5명 커피 쿠폰 — 사용자 50명 이상일 때. 필요: Apple/Google 로그인 자격, 동점 = 먼저 도달, 상위 기록 수동 확인, 당첨자 연락처 동의, 앱 내 공식 규칙
- [ ] (나중에) 내부 ID를 Tocko로 — 사용자 결정 2026-10-12: 지금은 보이는 이름만 Tocko, iOS 번들 ID는 출시 위해 유지
  - iOS 번들 ID com.looinlabs.focusone(+ .FocusMonitor), App Group group.com.looinlabs.focusone → tocko: Family Controls 배포 승인을 새 ID로 다시 받아야 함(수일~수주). 승인 후 업데이트로
  - 채널 이름 focusone/lock, ManagedSettingsStore 'focusone', Dart 패키지 focus_one, CI 산출물 이름 focus-one, 저장소 이름
  - 주의: 데이터 파일 focus_one_data.json·데스크탑 앱 데이터 경로는 패키지명에 묶임 → 바꾸면 기존 기록 이전 코드 필요
- [ ] (나중에) macOS 버전 출시 — 폰 출시 후. macos/ 커밋·앱 이름 Tocko(지금은 focus_one으로 보임)·Developer ID 서명+공증 또는 Mac App Store
- [ ] (보류) Apple Developer 공증 — 경고 없는 배포가 필요해지면
