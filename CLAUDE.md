# FocusOne — 프로젝트 규칙

Flutter 앱: 데스크탑(Windows/macOS/Linux) 미니 위젯 + 폰(iOS/Android). ADHD용 싱글 태스크 집중.

- `ios/`·`android/`는 커밋한다(앱 잠금 네이티브 코드). `macos/`·`windows/`·`linux/`·`build/`는 커밋하지 않는다 — `flutter create --platforms=<os> .` 후 `bash tool/apply_icons.sh` (CI도 동일).
- 번들 ID: `com.looinlabs.focusone` (iOS·Android 공통).
- 폰 진입점은 `lib/mobile/` (`main.dart`에서 iOS/Android 분기). 데스크탑 전용 서비스(창·트레이·단축키·local_notifier)는 폰에서 호출 금지.
- 색상/크기/간격은 반드시 `lib/core/design_tokens.dart` 토큰 참조 — 화면 코드에 하드코딩 금지.
- 장면(숲/밤/바다) 관련 값은 전부 `FocusScene` enum에 모은다 (색·아이콘·사운드 경로).
- 상태는 `AppState`(provider) 단일 ChangeNotifier. 서비스 연동은 main.dart에서 listener로.
- 저장은 LocalStore JSON 단일 파일. 필드 추가 시 fromJson 기본값 필수 (구버전 파일 호환).
- 검증: `flutter analyze` + `flutter test` 통과가 최소선.
