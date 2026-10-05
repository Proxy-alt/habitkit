import WidgetKit
import SwiftUI
import AppIntents
import SwiftData
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

// MARK: - Widget Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
    let nextIncomplete: String?
    let currentStreak: Int
    let theme: NookTheme
}

// MARK: - Intent Configuration

struct HabitWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Habit Widget"
    static let description = IntentDescription("Shows your habit progress for today.")
}

// MARK: - Provider

struct HabitWidgetProvider: AppIntentTimelineProvider {
    typealias Intent = HabitWidgetConfigurationIntent
    typealias Entry = HabitWidgetEntry

    func placeholder(in context: Context) -> HabitWidgetEntry {
        .init(date: .now, completedCount: 3, totalCount: 5, nextIncomplete: "Meditation", currentStreak: 7, theme: NookThemeManager().current)
    }

    func snapshot(for configuration: HabitWidgetConfigurationIntent, in context: Context) async -> HabitWidgetEntry {
        placeholder(in: context)
    }

    func timeline(for configuration: HabitWidgetConfigurationIntent, in context: Context) async -> Timeline<HabitWidgetEntry> {
        let entry = await makeEntry()
        let nextUpdate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func makeEntry() async -> HabitWidgetEntry {
        let themes = NookThemeManager()
        // In a real extension, load from shared ModelContainer
        return .init(date: .now, completedCount: 0, totalCount: 0, nextIncomplete: nil, currentStreak: 0, theme: themes.current)
    }
}

// MARK: - Views

struct HabitWidgetSmallView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base))

            VStack(spacing: 4) {
                NookProgressRing(progress: progress, lineWidth: 8, size: 70) {
                    VStack(spacing: 0) {
                        Text("\(entry.completedCount)")
                            .font(.nook(.title))
                            .foregroundStyle(.nook(.text))
                        Text("/ \(entry.totalCount)")
                            .font(.nook(.caption))
                            .foregroundStyle(.nook(.subtext))
                    }
                }
                Text("Today")
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
            }
        }
        .nookTheme(entry.theme)
    }
}

struct HabitWidgetMediumView: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base))

            HStack(spacing: 16) {
                NookProgressRing(progress: progress, lineWidth: 8, size: 80) {
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.nook(.headline))
                            .foregroundStyle(.nook(.text))
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.nook(.headline))
                        .foregroundStyle(.nook(.text))

                    Text("\(entry.completedCount) of \(entry.totalCount) done")
                        .font(.nook(.body))
                        .foregroundStyle(.nook(.subtext))

                    if let next = entry.nextIncomplete {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundStyle(.nook(.primary))
                            Text(next)
                                .font(.nook(.body))
                                .foregroundStyle(.nook(.text))
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.nook(.warning))
                        Text("\(entry.currentStreak) day streak")
                            .font(.nook(.caption))
                            .foregroundStyle(.nook(.subtext))
                    }
                }

                Spacer()
            }
            .padding()
        }
        .nookTheme(entry.theme)
    }
}

struct HabitWidgetLockScreenCircular: View {
    let entry: HabitWidgetEntry

    private var progress: Double {
        guard entry.totalCount > 0 else { return 0 }
        return Double(entry.completedCount) / Double(entry.totalCount)
    }

    var body: some View {
        Gauge(value: progress) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text("\(entry.completedCount)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct HabitWidgetLockScreenRectangular: View {
    let entry: HabitWidgetEntry

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("\(entry.completedCount) of \(entry.totalCount) habits done")
                .font(.nook(.caption))
        }
    }
}

struct HabitWidgetAccessoryInline: View {
    let entry: HabitWidgetEntry

    var body: some View {
        if let next = entry.nextIncomplete {
            Label(next, systemImage: "chevron.right.circle.fill")
        } else {
            Label("All done!", systemImage: "checkmark.circle.fill")
        }
    }
}

// MARK: - Widget Bundle

struct HabitWidget: Widget {
    let kind = "HabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HabitWidgetConfigurationIntent.self, provider: HabitWidgetProvider()) { entry in
            Group {
                HabitWidgetSmallView(entry: entry)
            }
        }
        .configurationDisplayName("Habit Progress")
        .description("See your habit completion for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
