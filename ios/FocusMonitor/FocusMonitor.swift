import DeviceActivity
import ManagedSettings
import Foundation

/// 앱이 꺼져 있어도 세션 종료 시각에 잠금을 푼다.
/// 활동 이름 "focus.<세션ID>"가 현재 진행 세션과 같을 때만 해제 — 지난 세션 콜백이 새 잠금을 풀지 않게.
final class FocusMonitor: DeviceActivityMonitor {
  private let defaults = UserDefaults(suiteName: "group.com.looinlabs.focusone")
  private let store = ManagedSettingsStore(named: .init("focusone"))

  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    let active = defaults?.string(forKey: "activeSessionId")
    guard active == nil || activity.rawValue == "focus.\(active!)" else { return }
    store.clearAllSettings()
    defaults?.removeObject(forKey: "activeSessionId")
    defaults?.removeObject(forKey: "endsAt")
  }
}
