# FocusOne memory

## 배포
- GitHub Actions 산출물은 서명·공증이 없어 macOS Gatekeeper가 차단 → CI에서 ad-hoc 서명(`codesign -s -`)만 하고, 사용자는 `xattr -cr` 로 격리 해제. 공증은 Apple Developer $99/년이라 보류.
- 이 맥에는 소스가 있으므로 로컬 빌드(`flutter build macos --release`)가 정답 — 격리 속성이 아예 안 붙음.

## 디자인 원본 (2026-07-14)
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
