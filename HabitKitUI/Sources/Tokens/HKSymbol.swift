// MARK: - HKSymbol

/// Canonical SF Symbol name constants used throughout HabitKitUI.
///
/// Using these constants prevents typos and makes symbol usage searchable:
/// ```swift
/// Image(systemName: HKSymbol.checkmark)
/// ```
public enum HKSymbol {

    // MARK: Completion

    /// `"checkmark.circle.fill"` — completed state indicator.
    public static let checkmark = "checkmark.circle.fill"

    /// `"checkmark.circle"` — incomplete state indicator.
    public static let checkmarkEmpty = "checkmark.circle"

    /// `"checkmark.seal.fill"` — verified or certified badge.
    public static let checkmarkSeal = "checkmark.seal.fill"

    // MARK: Actions

    /// `"plus"` — add action.
    public static let plus = "plus"

    /// `"trash.fill"` — delete action.
    public static let trash = "trash.fill"

    /// `"archivebox"` — archive action.
    public static let archivebox = "archivebox"

    /// `"square.and.arrow.up"` — share action.
    public static let squareArrowUp = "square.and.arrow.up"

    /// `"link"` — link or URL action.
    public static let link = "link"

    // MARK: Navigation & Controls

    /// `"chevron.right"` — forward / disclosure indicator.
    public static let chevronRight = "chevron.right"

    /// `"chevron.right.circle.fill"` — filled forward / disclosure button.
    public static let chevronRightCircle = "chevron.right.circle.fill"

    /// `"gear"` — settings.
    public static let gear = "gear"

    /// `"list.bullet"` — list view.
    public static let list = "list.bullet"

    /// `"info.circle"` — informational disclosure.
    public static let infoCircle = "info.circle"

    // MARK: Stats & Progress

    /// `"flame.fill"` — streak indicator.
    public static let flame = "flame.fill"

    /// `"trophy.fill"` — achievement or milestone.
    public static let trophy = "trophy.fill"

    /// `"chart.bar.fill"` — bar chart.
    public static let chartBar = "chart.bar.fill"

    /// `"chart.bar.xaxis"` — bar chart with axis.
    public static let chartBarX = "chart.bar.xaxis"

    // MARK: Playback & Time

    /// `"timer"` — timer or countdown.
    public static let timer = "timer"

    /// `"play.circle.fill"` — start / play action.
    public static let play = "play.circle.fill"

    // MARK: Appearance

    /// `"sparkles"` — highlight or celebration.
    public static let sparkles = "sparkles"

    /// `"paintpalette.fill"` — theme / colour picker.
    public static let paintpalette = "paintpalette.fill"

    /// `"moon.fill"` — dark mode.
    public static let moon = "moon.fill"

    /// `"sun.max.fill"` — light mode.
    public static let sun = "sun.max.fill"

    // MARK: System & Connectivity

    /// `"icloud.fill"` — iCloud sync.
    public static let icloud = "icloud.fill"

    /// `"hand.tap.fill"` — interaction hint.
    public static let handTap = "hand.tap.fill"

    /// `"bell.fill"` — notifications.
    public static let bell = "bell.fill"

    // MARK: Habit Icons — Activity

    /// `"figure.run"` — running habit.
    public static let figureRun = "figure.run"

    /// `"figure.walk"` — walking habit.
    public static let figureWalk = "figure.walk"

    /// `"bicycle"` — cycling habit.
    public static let bicycle = "bicycle"

    /// `"dumbbell.fill"` — strength training habit.
    public static let dumbbell = "dumbbell.fill"

    // MARK: Habit Icons — Health & Wellness

    /// `"heart.fill"` — health / favourites.
    public static let heart = "heart.fill"

    /// `"drop.fill"` — hydration habit.
    public static let drop = "drop.fill"

    /// `"pills.fill"` — medication habit.
    public static let pills = "pills.fill"

    /// `"bed.double.fill"` — sleep habit.
    public static let bed = "bed.double.fill"

    /// `"brain.head.profile"` — mindfulness or mental health habit.
    public static let brain = "brain.head.profile"

    // MARK: Habit Icons — Lifestyle

    /// `"book.fill"` — reading habit.
    public static let book = "book.fill"

    /// `"leaf.fill"` — nature or sustainability habit.
    public static let leaf = "leaf.fill"

    /// `"fork.knife"` — nutrition or meal habit.
    public static let fork = "fork.knife"

    /// `"music.note"` — music or practice habit.
    public static let music = "music.note"

    /// `"pencil"` — journaling or writing habit.
    public static let pencil = "pencil"

    /// `"laptopcomputer"` — work or study habit.
    public static let laptop = "laptopcomputer"

    /// `"star.fill"` — favourite or featured.
    public static let star = "star.fill"
}
