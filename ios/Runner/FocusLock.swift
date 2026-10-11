import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

/// 집중 중 앱 잠금 (Family Controls). 채널: focusone/lock
/// - 선택한 앱 목록·진행 세션 ID는 App Group에 저장 → FocusMonitor 확장이 Flutter 없이 해제한다.
/// - DeviceActivity 최소 감시 구간 15분 → 15분 미만 세션은 잠그지 않는다(Dart 쪽에서 막음).
final class FocusLock: NSObject, FlutterPlugin {
  static let group = "group.com.looinlabs.focusone"
  static let store = ManagedSettingsStore(named: .init("focusone"))
  private let center = DeviceActivityCenter()
  private var defaults: UserDefaults { UserDefaults(suiteName: Self.group)! }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "focusone/lock", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(FocusLock(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "status":
      result([
        "authorized": AuthorizationCenter.shared.authorizationStatus == .approved,
        "selectedCount": selectionCount(loadSelection()),
      ])
    case "authorize":
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          result(true)
        } catch {
          result(false)
        }
      }
    case "pickApps":
      presentPicker(result: result)
    case "start":
      guard let sessionId = args["sessionId"] as? String,
            let endsAtMs = args["endsAtMs"] as? Int else {
        return result(FlutterError(code: "args", message: "sessionId, endsAtMs 필요", details: nil))
      }
      result(start(sessionId: sessionId, endsAt: Date(timeIntervalSince1970: Double(endsAtMs) / 1000)))
    case "stop":
      stop()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: 선택 앱 저장
  private func loadSelection() -> FamilyActivitySelection {
    guard let data = defaults.data(forKey: "selection"),
          let sel = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    else { return FamilyActivitySelection() }
    return sel
  }

  private func saveSelection(_ sel: FamilyActivitySelection) {
    defaults.set(try? PropertyListEncoder().encode(sel), forKey: "selection")
  }

  private func selectionCount(_ s: FamilyActivitySelection) -> Int {
    s.applicationTokens.count + s.categoryTokens.count + s.webDomainTokens.count
  }

  private func presentPicker(result: @escaping FlutterResult) {
    let model = PickerModel(selection: loadSelection())
    let host = UIHostingController(rootView: PickerSheet(model: model) { [weak self] sel in
      self?.saveSelection(sel)
      result(self?.selectionCount(sel) ?? 0)
    })
    let root = UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
    var top = root
    while let p = top?.presentedViewController { top = p }
    top?.present(host, animated: true)
  }

  // MARK: 잠금 시작/해제
  private func start(sessionId: String, endsAt: Date) -> Bool {
    let sel = loadSelection()
    guard selectionCount(sel) > 0, endsAt.timeIntervalSinceNow >= 15 * 60 - 5 else { return false }
    center.stopMonitoring() // 이전 세션 예약 제거 → 오래된 콜백이 새 잠금을 풀지 못함
    defaults.set(sessionId, forKey: "activeSessionId")
    Self.applyShield(sel)
    let cal = Calendar.current
    let comps: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let schedule = DeviceActivitySchedule(
      intervalStart: cal.dateComponents(comps, from: Date()),
      intervalEnd: cal.dateComponents(comps, from: endsAt),
      repeats: false)
    do {
      try center.startMonitoring(.init("focus.\(sessionId)"), during: schedule)
      return true
    } catch {
      stop() // 예약 실패 시 잠금을 남겨두지 않는다
      return false
    }
  }

  private func stop() {
    center.stopMonitoring()
    defaults.removeObject(forKey: "activeSessionId")
    Self.store.clearAllSettings()
  }

  static func applyShield(_ sel: FamilyActivitySelection) {
    store.shield.applications = sel.applicationTokens.isEmpty ? nil : sel.applicationTokens
    store.shield.applicationCategories = sel.categoryTokens.isEmpty ? nil : .specific(sel.categoryTokens)
    store.shield.webDomains = sel.webDomainTokens.isEmpty ? nil : sel.webDomainTokens
  }
}

final class PickerModel: ObservableObject {
  @Published var selection: FamilyActivitySelection
  init(selection: FamilyActivitySelection) { self.selection = selection }
}

struct PickerSheet: View {
  @ObservedObject var model: PickerModel
  let onDone: (FamilyActivitySelection) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      FamilyActivityPicker(selection: $model.selection)
        .navigationTitle("집중 중 잠글 앱")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("완료") { onDone(model.selection); dismiss() }
          }
        }
    }
  }
}
