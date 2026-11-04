import ActivityKit
import Flutter
import Foundation

/// 휴식 Live Activity 시작·종료. 채널: focusone/break
/// start {endsAt: ms} — 이미 떠 있으면 시각만 바꿈 / end
enum BreakActivity {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "focusone/break", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else { return result(nil) }
      switch call.method {
      case "start":
        let ms = (call.arguments as? [String: Any])?["endsAt"] as? Double ?? 0
        start(Date(timeIntervalSince1970: ms / 1000))
      case "end":
        end()
      default:
        return result(FlutterMethodNotImplemented)
      }
      result(nil)
    }
  }

  @available(iOS 16.2, *)
  private static func start(_ endsAt: Date) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let content = ActivityContent(state: BreakAttributes.ContentState(endsAt: endsAt), staleDate: endsAt)
    if let a = Activity<BreakAttributes>.activities.first {
      Task { await a.update(content) }
      return
    }
    _ = try? Activity.request(attributes: BreakAttributes(), content: content)
  }

  @available(iOS 16.2, *)
  private static func end() {
    for a in Activity<BreakAttributes>.activities {
      Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
  }
}
