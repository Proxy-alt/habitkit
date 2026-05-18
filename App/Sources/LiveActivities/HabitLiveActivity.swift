import ActivityKit
import SwiftUI
import WidgetKit
import HabitKitCore
import HabitKitUI

public struct HabitLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingSeconds: Int
        public var habitName: String
        public var isComplete: Bool
    }

    public var habitID: UUID
    public var habitName: String
    public var targetSeconds: Int

    public init(habitID: UUID, habitName: String, targetSeconds: Int) {
        self.habitID = habitID
        self.habitName = habitName
        self.targetSeconds = targetSeconds
    }
}

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
            HKProgressRing(progress: progress, lineWidth: 5, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.habitName)
                    .font(.hkHeadline)
                if context.state.isComplete {
                    Text("Complete!")
                        .font(.hkCaption)
                        .foregroundStyle(.green)
                } else {
                    Text(timerString(context.state.remainingSeconds))
                        .font(.hkMono)
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
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(.purple)
                        .font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerString(context.state.remainingSeconds))
                        .font(.hkMono)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.habitName)
                        .font(.hkHeadline)
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
                    .font(.hkCaption)
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
