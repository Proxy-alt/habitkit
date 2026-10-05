import ActivityKit
import SwiftUI
import WidgetKit
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct HabitLiveActivityView: View {
    let context: ActivityViewContext<HabitLiveActivityAttributes>

    private var progress: Double {
        let remaining = Double(context.state.remainingSeconds)
        let total = Double(context.attributes.targetSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }

    var body: some View {
        HStack(spacing: 12) {
            NookProgressRing(progress: progress, lineWidth: 5, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.habitName)
                    .font(.nook(.headline))
                if context.state.isComplete {
                    Text("Complete!")
                        .font(.nook(.caption))
                        .foregroundStyle(.green)
                } else {
                    Text(timerString(context.state.remainingSeconds))
                        .font(.nook(.mono))
                        .monospacedDigit()
                }
            }

            Spacer()
        }
        .padding()
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct HabitLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitLiveActivityAttributes.self) { context in
            HabitLiveActivityView(context: context)
                .background(.black.opacity(0.85))
                // The extension is a separate process from the app, so it never
                // gets the theme applied at the app root. Without this the
                // ring falls back to the Mocha default instead of the saved theme.
                .nookTheme(NookThemeManager.habitNook().current)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.purple)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerString(context.state.remainingSeconds))
                        .font(.nook(.mono))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.habitName)
                        .font(.nook(.headline))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: expandedProgress(context))
                        .tint(.purple)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(.purple)
            } compactTrailing: {
                Text(timerString(context.state.remainingSeconds))
                    .font(.nook(.caption))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(.purple)
            }
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func expandedProgress(_ context: ActivityViewContext<HabitLiveActivityAttributes>) -> Double {
        let remaining = Double(context.state.remainingSeconds)
        let total = Double(context.attributes.targetSeconds)
        guard total > 0 else { return 0 }
        return 1.0 - (remaining / total)
    }
}
