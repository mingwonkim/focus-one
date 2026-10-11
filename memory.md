# FocusOne memory

## 배포
- GitHub Actions 산출물은 서명·공증이 없어 macOS Gatekeeper가 차단 → CI에서 ad-hoc 서명(`codesign -s -`)만 하고, 사용자는 `xattr -cr` 로 격리 해제. 공증은 Apple Developer $99/년이라 보류.
- 이 맥에는 소스가 있으므로 로컬 빌드(`flutter build macos --release`)가 정답 — 격리 속성이 아예 안 붙음.

## 디자인 v2 (2026-10-08 사용자 확정 → main 머지) — 현재 디자인 원본
- 주 레퍼런스 Tiimo 집중 화면(Mobbin) — 사용자가 A안 선택. **링 안에 장면 일러스트**(숲/달토끼/고래)를 넣는 게 사용자 요구 — 사운드 장면이 강점.
- 설계서: astra(`docs/v2/app-design-spec.md`), 변경 근거 `docs/v2/app-deviations.md`. 바탕화면 시안 3종(.dc.html)은 v1 원본 — v2가 대체함.
- 시간 글자는 링 밖(아래). 링 안 글자 없으니 SceneDialPainter 베일 제거.
- 미리보기 PNG: `flutter test tool/preview --dart-define=OUT=<dir>` (macOS AppleGothic·MaterialIcons 로드). 탭 전환 캡처는 AnimatedSwitcher 첫 프레임이 opacity 0이라 pump 2번 더 필요.
- 비선택 작업 체크 = `completeTask(id)` — 타이머·현재 작업 보존(selectTask 경유 금지).

## 모바일 v1 (2026-10-11, mobile-v1 브랜치)
- 레퍼런스: App Store "Arctic Habit"(iPhone 미러링 실측, docs/mobile/refs). 레이아웃 패턴만 참고, 콘셉트·문구·그림은 자체 — 심사 4.1(카피캣) 대응. 사용자 지적으로 GitHub식 잔디 → 장면색 집중 달력으로 교체.
- 구조: `lib/mobile/`(셸·탭 4개), `main.dart`에서 iOS/Android 분기. 데스크탑 전용 서비스 호출 금지. 폰은 `autoBreak=false`(휴식은 보상 시트에서 선택).
- 타이머는 시각 기준(package:clock) + 진행 세션(ActiveSession) 저장 → 재실행 이어가기, 세션 ID로 기록·보상 1회. 실집중 구간(segments) 저장해 통계가 일시정지·복구에 왜곡되지 않음.
- 앱 잠금: iOS Family Controls(FocusLock.swift + FocusMonitor 확장, App Group group.com.looinlabs.focusone, DeviceActivity 최소 15분 → 15분 이상 세션만), Android 접근성 서비스(패키지명만, 만료 후 미차단). 배포용 Family Controls 권한 신청 2026-10-11 — 승인 전엔 App Store/TestFlight 서명 불가.
- 그림: Higgsfield 크레딧 소진 → codex 내장 이미지 생성(무료)으로 친구 12·장식 9. 소리: tool/gen_sounds.py 합성(장면 3 + 상황 5 + 소음 3).
- 리뷰: astra 리뷰 1(12건) 반영 기록 docs/mobile/review-1.md.
- Android 업로드 키: `~/.config/focusone/upload-keystore.jks` + key.properties (저장소 밖, 분실 시 Play 업로드 키 재설정 필요 → 백업 필수).

## 앱 아이콘 v2 (2026-10-11) — 현재
- 사용자 선택: "네 친구 빼꼼" F3-b — 숲·밤·바다·일상 친구(새싹사슴·달토끼·물결고래·갈색 라떼멍) 얼굴이 네 색 링 아래로 빼꼼. 앱 안 캐릭터와 같은 스타일이어야 한다는 사용자 지적으로 H3(실사풍 고래) 교체.
- 원본 `assets/icon/source.png`(1024 불투명) → `python3 tool/make_icons.py` 가 iOS·macOS·Windows·Linux·트레이·Android 전부 생성.
- 과정: 고래 A·사슴·달토끼·라떼멍·네 친구 비교 → "부담스럽다" 피드백(큰 눈·꽉 찬 구성) → 작게·눈웃음·여백 → 빼꼼 + 얼굴 1.5배.

## 앱 아이콘 v1 (2026-10-08)
- 사용자 선택: Higgsfield 시안 H3(바다·고래, gpt_image_2_5, job 7dc1b3a0…). 기록 `docs/v2/higgsfield-log.md`.
- 생성 이미지의 회색 배경은 크레딧 대신 PIL로 스퀘어클(n=5) 마스크 처리 → macOS 1024(본체 824+여백 100+그림자), Windows .ico·Linux 256·트레이는 여백 없는 타일.
- 플랫폼 폴더는 커밋 안 하므로 `flutter create` 후 `bash tool/apply_icons.sh` 필수 (CI에도 단계 추가). 트레이 아이콘은 pubspec assets 등록 필요.

## 디자인 원본 v1 (2026-07-14)
- **디자인의 단일 원본은 바탕화면의 시안 3종**: `~/Desktop/FocusOne Forest v3.dc.html`, `FocusOne Night.dc.html`, `FocusOne Ocean.dc.html`. 색·크기·문구 전부 여기서 추출해 `SceneStyle`(design_tokens.dart)에 옮겼다 — 임의 변경 금지.
- 다이얼 안 풍경(숲/달토끼/고래)은 `SceneDialPainter`(core/scene_decorations.dart)가 지름 비율 좌표로 그린다 (88px 미니/216px 확장 공용).
- 시안에 없어서 추가한 최소 기능: 미니 우하단 패널 열기 아이콘, 헤더 접기 아이콘, 세션 라벨 탭→길이 메뉴, 섹션 헤더의 인박스/차단 전환, 리스트 하단 할 일 입력. 뱃지 탭 = 모드 순환.
- 시안의 배경 풍경(나무들/유성/고래 유영)은 쇼케이스 배경이지 앱 창이 아님 — 구현 대상 아님.
- 패널 560px 고정이라 인박스/차단 뷰에서는 216px 다이얼을 소형 타이머 줄(`_CompactTimerStrip`)로 접는다 — 내용 공간 확보용, 사용자 요청(2026-07-14 편의성 개선).
- 카드가 배경색을 직접 칠하므로 ListTile/잉크 쓰는 내부에는 `Material(type: transparency)` 필요.

## 장면 모드 (2026-07-14)
- `FocusScene` enum(core/design_tokens.dart)이 단일 소스: 테마 색 + 아이콘 + 사운드 경로를 enum 멤버로 보유. 라이트/다크 시스템 테마는 제거하고 장면이 테마를 결정.
- 앰비언트 사운드는 저작권 없는 파일 확보 대신 Python stdlib로 합성 — 재생성: `python3 tool/gen_sounds.py assets/sounds` (40초 루프, 경계 크로스페이드). 재생은 audioplayers, **집중 중(focus+running)에만** 루프 — 대기/휴식/일시정지 시 정지.
- 사운드 on/off·볼륨은 확장 패널 헤더의 스피커 팝업에서 조절, StoreData에 저장 (기본 on/0.6). 슬라이더 드래그 중엔 persist:false — 파일 쓰기 폭주 방지.
- 위젯 테스트는 Ahem 폰트(글자당 1em)라 실제보다 텍스트가 훨씬 넓다 — 헤더처럼 좁은 Row의 Text엔 maxLines/Flexible 필수 (2026-07-14 오버플로 원인).
- audioplayers 때문에 Linux CI에 gstreamer dev 패키지, .deb Depends에 gstreamer 런타임 추가됨.

- 2026-10-11 폰 집중 강제: 일시정지 없음, 그만두기는 시작 10초 안 취소만. 실수 출구는 물방울 비상 탈출(남은 1분당 2개 = 모은 속도의 2배라 아깝게, 결과는 그만두기와 같아 보상 없음). '시간 단축'은 보상을 사는 셈이라 기각.
- 2026-10-11 랭킹: Supabase 프로젝트 focusone(ref bvnwdbbjkrjdqgqyidhp, 서울, DB 비번 ~/.config/focusone/). 익명 로그인 + 닉네임 옵트인. 테이블 RLS 정책 없음 → security definer 함수(submit_score/ranking/leave_ranking)로만. 점수는 앱 rankScore(모은 물방울 − 비상 탈출, 상점 구매는 유지)를 보내고 서버가 차이만 반영: 하루(KST) +720(사용자 결정 12시간), 직전 제출 뒤 경과 분 이상 못 오름. 주간 = 월요일 KST 시작.
