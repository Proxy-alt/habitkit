import WidgetKit
import SwiftUI
import AppIntents
import SwiftData
import HabitKitCore
import HabitKitUI

// MARK: - Widget Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let completedCount: Int
    let totalCount: Int
    let nextIncomplete: String?
    let currentStreak: Int
    let theme: HKTheme
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
        .init(date: .now, completedCount: 3, totalCount: 5, nextIncomplete: "Meditation", currentStreak: 7, theme: HKThemeManager().current)
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
        let themes = HKThemeManager()
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
            entry.theme.baseColor

            VStack(spacing: 4) {
                HKProgressRing(progress: progress, lineWidth: 8, size: 70) {
                    VStack(spacing: 0) {
                        Text("\(entry.completedCount)")
                            .font(.hkTitle)
                            .foregroundStyle(entry.theme.textColor)
                        Text("/ \(entry.totalCount)")
                            .font(.hkCaption)
                            .foregroundStyle(entry.theme.subtextColor)
                    }
                }
                Text("Today")
                    .font(.hkCaption)
                    .foregroundStyle(entry.theme.subtextColor)
            }
        }
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
            entry.theme.baseColor

            HStack(spacing: 16) {
                HKProgressRing(progress: progress, lineWidth: 8, size: 80) {
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.hkHeadline)
                            .foregroundStyle(entry.theme.textColor)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.hkHeadline)
                        .foregroundStyle(entry.theme.textColor)

                    Text("\(entry.completedCount) of \(entry.totalCount) done")
                        .font(.hkBody)
                        .foregroundStyle(entry.theme.subtextColor)

                    if let next = entry.nextIncomplete {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundStyle(entry.theme.primaryColor)
                            Text(next)
                                .font(.hkBody)
                                .foregroundStyle(entry.theme.textColor)
                                .lineLimit(1)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(entry.theme.warningColor)
                        Text("\(entry.currentStreak) day streak")
                            .font(.hkCaption)
                            .foregroundStyle(entry.theme.subtextColor)
                    }
                }

                Spacer()
            }
            .padding()
        }
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
                .font(.hkCaption)
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
