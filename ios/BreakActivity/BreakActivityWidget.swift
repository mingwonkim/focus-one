import ActivityKit
import SwiftUI
import WidgetKit

/// 휴식 중: 잠금 화면 + Dynamic Island에 남은 시간
@main
struct BreakActivityBundle: WidgetBundle {
  var body: some Widget { BreakActivityWidget() }
}

private let green = Color(red: 0x24 / 255, green: 0x6B / 255, blue: 0x4B / 255)
private let mint = Color(red: 0xEE / 255, green: 0xF7 / 255, blue: 0xF1 / 255)

struct BreakActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BreakAttributes.self) { ctx in
      HStack(spacing: 14) {
        Image(systemName: "cup.and.saucer.fill").font(.title2).foregroundStyle(green)
        VStack(alignment: .leading, spacing: 2) {
          Text("휴식 중").font(.headline)
          Text("끝나면 다시 집중해요").font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        timer(ctx.state.endsAt).font(.system(size: 36, weight: .semibold)).foregroundStyle(green)
      }
      .padding(18)
      .activityBackgroundTint(mint)
      .activitySystemActionForegroundColor(green)
    } dynamicIsland: { ctx in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label("휴식", systemImage: "cup.and.saucer.fill").font(.headline).foregroundStyle(.mint)
        }
        DynamicIslandExpandedRegion(.trailing) {
          timer(ctx.state.endsAt).font(.title2.weight(.semibold))
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("끝나면 다시 집중해요").font(.caption).foregroundStyle(.secondary)
        }
      } compactLeading: {
        Image(systemName: "cup.and.saucer.fill").foregroundStyle(.mint)
      } compactTrailing: {
        timer(ctx.state.endsAt).frame(width: 44).foregroundStyle(.mint)
      } minimal: {
        Image(systemName: "cup.and.saucer.fill").foregroundStyle(.mint)
      }
    }
  }

  /// 시스템이 직접 줄여 주는 카운트다운 (앱이 꺼져 있어도 흐름)
  private func timer(_ end: Date) -> some View {
    Text(timerInterval: Date()...max(end, Date()), countsDown: true)
      .monospacedDigit()
      .multilineTextAlignment(.trailing)
  }
}
