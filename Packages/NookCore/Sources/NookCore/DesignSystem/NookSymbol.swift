// MARK: - NookSymbol

/// SF Symbol names used across the suite.
///
/// A typed enum rather than string constants: a misspelt case fails to
/// compile, and `CaseIterable` lets tests check every name exists on the
/// oldest supported OS. NookUI adds `Image(nookSymbol:)` and
/// `Label(_:nookSymbol:)`.
public enum NookSymbol: String, CaseIterable, Sendable {

    // MARK: Completion

    case checkmark = "checkmark.circle.fill"
    case checkmarkEmpty = "checkmark.circle"
    case checkmarkSeal = "checkmark.seal.fill"

    // MARK: Actions

    case plus = "plus"
    case trash = "trash.fill"
    case archivebox = "archivebox"
    case squareArrowUp = "square.and.arrow.up"
    case link = "link"

    // MARK: Navigation & Controls

    case chevronRight = "chevron.right"
    case chevronRightCircle = "chevron.right.circle.fill"
    case gear = "gear"
    case list = "list.bullet"
    case infoCircle = "info.circle"

    // MARK: Stats & Progress

    case flame = "flame.fill"
    case trophy = "trophy.fill"
    case chartBar = "chart.bar.fill"
    case chartBarX = "chart.bar.xaxis"

    // MARK: Playback & Time

    case timer = "timer"
    case play = "play.circle.fill"

    // MARK: Appearance

    case sparkles = "sparkles"
    case paintpalette = "paintpalette.fill"
    case moon = "moon.fill"
    case sun = "sun.max.fill"

    // MARK: System & Connectivity

    case icloud = "icloud.fill"
    case handTap = "hand.tap.fill"
    case bell = "bell.fill"

    // MARK: Habit Icons: Activity

    case figureRun = "figure.run"
    case figureWalk = "figure.walk"
    case bicycle = "bicycle"
    case dumbbell = "dumbbell.fill"

    // MARK: Habit Icons: Health & Wellness

    case heart = "heart.fill"
    case drop = "drop.fill"
    case pills = "pills.fill"
    case bed = "bed.double.fill"
    case brain = "brain.head.profile"

    // MARK: Habit Icons: Lifestyle

    case book = "book.fill"
    case leaf = "leaf.fill"
    case fork = "fork.knife"
    case music = "music.note"
    case pencil = "pencil"
    case laptop = "laptopcomputer"
    case star = "star.fill"
}
