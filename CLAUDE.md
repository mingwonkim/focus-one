# FocusOne — 프로젝트 규칙

Flutter 데스크탑 앱 (Windows/macOS/Linux). ADHD용 싱글 태스크 집중 미니 위젯.

- 저장소에는 `lib/`만 있음 — 플랫폼 폴더는 `flutter create --platforms=<os> .` 로 생성 (CI도 동일). `macos/`, `build/` 등은 커밋하지 않는다.
- 색상/크기/간격은 반드시 `lib/core/design_tokens.dart` 토큰 참조 — 화면 코드에 하드코딩 금지.
- 장면(숲/밤/바다) 관련 값은 전부 `FocusScene` enum에 모은다 (색·아이콘·사운드 경로).
- 상태는 `AppState`(provider) 단일 ChangeNotifier. 서비스 연동은 main.dart에서 listener로.
- 저장은 LocalStore JSON 단일 파일. 필드 추가 시 fromJson 기본값 필수 (구버전 파일 호환).
- 검증: `flutter analyze` + `flutter test` 통과가 최소선.
