// MARK: - NookContrastRequirement

/// A foreground/background role pairing that must meet a WCAG contrast ratio.
///
/// ``suite`` lists every pairing the shared components draw. Built-in themes
/// are tested against it, and theme import rejects community themes that
/// fail it.
public struct NookContrastRequirement: Hashable, Sendable {

    /// WCAG 1.4.3: body text.
    public static let textMinimum = 4.5

    /// WCAG 1.4.11: icons, focus rings, progress fills, and other non-text UI.
    public static let nonTextMinimum = 3.0

    public let foreground: NookColour
    public let background: NookColour
    public let minimumRatio: Double

    public init(_ foreground: NookColour, on background: NookColour, minimumRatio: Double) {
        self.foreground = foreground
        self.background = background
        self.minimumRatio = minimumRatio
    }

    /// Pairings used by NookUI components.
    ///
    /// `overlay0` is absent on purpose: WCAG exempts disabled controls, and
    /// placeholders must not be the only label for a field.
    public static let suite: [NookContrastRequirement] = [
        // Body and secondary text on every surface text appears on.
        .init(.text, on: .base, minimumRatio: textMinimum),
        .init(.text, on: .surface0, minimumRatio: textMinimum),
        .init(.text, on: .surface1, minimumRatio: textMinimum),
        .init(.subtext, on: .base, minimumRatio: textMinimum),
        .init(.subtext, on: .surface0, minimumRatio: textMinimum),
        // Filled button labels (NookButton .primary and .danger).
        .init(.base, on: .primary, minimumRatio: textMinimum),
        .init(.base, on: .danger, minimumRatio: textMinimum),
        // Status colours as icons, rings, and fills.
        .init(.primary, on: .base, minimumRatio: nonTextMinimum),
        .init(.primary, on: .surface0, minimumRatio: nonTextMinimum),
        .init(.success, on: .base, minimumRatio: nonTextMinimum),
        .init(.success, on: .surface0, minimumRatio: nonTextMinimum),
        .init(.warning, on: .base, minimumRatio: nonTextMinimum),
        .init(.danger, on: .base, minimumRatio: nonTextMinimum),
    ]
}

// MARK: - NookContrastFailure

/// A requirement a theme did not meet, with the measured ratio.
public struct NookContrastFailure: Hashable, Sendable {
    public let requirement: NookContrastRequirement
    public let measuredRatio: Double
}

// MARK: - NookTheme audit

public extension NookTheme {

    /// The requirements this theme fails, empty when the theme passes.
    func contrastFailures(
        against requirements: [NookContrastRequirement] = NookContrastRequirement.suite
    ) -> [NookContrastFailure] {
        requirements.compactMap { requirement in
            let ratio = colors[requirement.foreground]
                .contrastRatio(on: colors[requirement.background])
            guard ratio < requirement.minimumRatio else { return nil }
            return NookContrastFailure(requirement: requirement, measuredRatio: ratio)
        }
    }
}
