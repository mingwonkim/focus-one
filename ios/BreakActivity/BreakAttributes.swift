import ActivityKit
import Foundation

/// 휴식 남은 시간 (Live Activity). Runner·BreakActivity 두 타깃이 함께 쓴다.
struct BreakAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var endsAt: Date
  }
}
