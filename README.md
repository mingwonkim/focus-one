# FocusOne (가칭)

ADHD 사용자를 위한 싱글 태스크 집중 데스크탑 미니 위젯.
**"지금 이거 하나만"** — 목록은 숨기고, 현재 작업 1개와 남은 시간만 항상 화면 위에 띄운다.

## 핵심 컨셉

| 문제 | 해결 |
|---|---|
| 작업 전환 과다 | 화면에 현재 작업 1개만 노출, 목록은 확장 패널에 숨김 |
| 딴생각으로 이탈 | `Ctrl+Shift+Space` 전역 단축키 → 생각을 인박스에 던지고 즉시 복귀 |
| 시간 감각 상실 (time blindness) | 숫자 대신 **줄어드는 원(Time Timer 방식)** 으로 남은 시간 시각화 |
| 시작 장벽 | 5 / 15 / 25 / 45분 짧은 스프린트 선택형 타이머 |
| 보상 부족 | 세션 완료 알림 + 오늘 집중 시간 + 연속일 스트릭 |

## 화면 구조

- **미니 위젯 (기본)**: 320×128, 항상 위(always-on-top), 프레임리스. 타이머 링 + 현재 작업 + 시작/일시정지
- **확장 패널**: 미니 위젯에서 펼침. 할 일 목록 / 인박스 / 타이머 길이 / 통계
- **퀵 캡처**: 전역 단축키로 호출. 입력 → Enter → 즉시 닫힘 (3초 안에 복귀가 목표)

## 실행 방법

Flutter SDK 3.27+ 필요 (`Color.withValues` 사용).

```bash
# 1. 저장소 클론 후 플랫폼 폴더 생성 (최초 1회)
flutter create --platforms=windows,macos .

# 2. 의존성 설치
flutter pub get

# 3. 실행
flutter run -d windows   # Windows
flutter run -d macos     # macOS
```

### macOS: 다운로드한 앱이 "손상됨/확인 불가"로 안 열릴 때

GitHub Actions 빌드는 Apple 공증(notarization)이 없어서 Gatekeeper가 차단한다.
zip을 푼 뒤 터미널에서 격리 속성을 제거하면 열린다:

```bash
xattr -cr ~/Downloads/focus_one.app   # 압축 푼 위치에 맞게 경로 수정
```

공증까지 하려면 Apple Developer Program($99/년) 가입 + 서명·공증 단계가 필요하다.
소스가 있는 맥에서는 그냥 `flutter build macos --release` 로 직접 빌드하면 격리 자체가 없다.

### 트레이 아이콘 준비 (필수는 아님)

`assets/` 폴더에 아래 파일을 넣으면 시스템 트레이 아이콘이 표시된다. 없어도 앱은 동작한다.

- Windows: `assets/tray_icon.ico` (16×16, 32×32 포함 권장)
- macOS: `assets/tray_icon.png` (22×22 @1x 권장)

## 기술 스택

- Flutter Desktop (Windows / macOS / Linux 단일 코드베이스)
- `provider` — 상태 관리
- `window_manager` — always-on-top, 프레임리스, 미니↔확장 창 전환
- `tray_manager` — 시스템 트레이 상주
- `hotkey_manager` — 전역 단축키
- `local_notifier` — 세션 완료 알림
- 저장소: 로컬 JSON 파일 (MVP, 추후 drift/isar 교체 예정)

## 폴더 구조

```
lib/
├── main.dart                 # 서비스 초기화·연결
├── app.dart                  # 모드별 화면 전환 셸
├── core/                     # 디자인 토큰, 테마
├── models/                   # Task, BrainDumpItem, FocusSession
├── data/                     # LocalStore (JSON 저장소)
├── state/                    # AppState (ChangeNotifier)
├── services/                 # window / tray / hotkey
└── features/
    ├── mini/                 # 미니 위젯 화면
    ├── expanded/             # 확장 패널 (할 일·인박스·통계)
    └── capture/              # 퀵 캡처 오버레이
```

## 로드맵

- [x] **Phase 1 (MVP)**: 미니 위젯, 타이머, 브레인덤프, 통계 바
- [ ] 사운드 피드백, 완료 애니메이션
- [ ] 설정 화면 (단축키 변경, 자동 시작, 테마)
- [ ] Windows 설치 파일 (MSIX / Inno Setup)
- [x] 방해 앱/사이트 감지·차단 (집중 중에만, 휴식 시 자동 해제)
- [x] 브라우저 확장 FocusOne Guard (영상 잠금, 앞으로 감기 차단, 중복 탭 차단 — `browser_extension/` 참고)
- [ ] **Phase 2**: 하이퍼포커스 알림, AI 작업 쪼개기, 확장↔앱 연동
- [ ] macOS 빌드·공증

## 라이선스

TBD
