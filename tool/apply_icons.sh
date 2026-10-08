#!/usr/bin/env bash
# flutter create 직후 실행: assets/icon 의 앱 아이콘을 생성된 플랫폼 폴더에 덮어쓴다.
# (플랫폼 폴더는 커밋하지 않으므로 로컬·CI 모두 매번 필요)
set -e
cd "$(dirname "$0")/.."
if [ -d macos ]; then
  cp assets/icon/macos/app_icon_*.png macos/Runner/Assets.xcassets/AppIcon.appiconset/
fi
if [ -d windows ]; then
  cp assets/icon/app_icon.ico windows/runner/resources/app_icon.ico
fi
