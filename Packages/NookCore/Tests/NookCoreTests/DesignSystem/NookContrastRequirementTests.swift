import Testing
@testable import NookCore

@Suite("NookContrastRequirement")
struct NookContrastRequirementTests {

    @Test("reports a failing pairing with its measured ratio")
    func reportsFailure() throws {
        let grey = NookRGBA(rgb: 0x777777)
        let palette = NookPalette(
            base: grey, surface0: grey, surface1: grey, surface2: grey, overlay0: grey,
            text: grey, subtext: grey, primary: grey, success: grey, warning: grey, danger: grey
        )
        let theme = NookTheme(id: "flat", name: "Flat", isDark: false, colors: palette)
        let requirement = NookContrastRequirement(.text, on: .base, minimumRatio: 4.5)
        let failure = try #require(theme.contrastFailures(against: [requirement]).first)
        #expect(failure.requirement == requirement)
        #expect(abs(failure.measuredRatio - 1) < 0.0001)
    }

    // Latte's text, subtext, success and warning are darkened from upstream
    // Catppuccin to pass; see nookui-design-doc.md 4.2.
    @Test("built-in themes meet the suite requirements", arguments: NookTheme.builtIn)
    func builtInsPass(theme: NookTheme) {
        expectNoFailures(in: theme)
    }

    private func expectNoFailures(in theme: NookTheme) {
        let failures = theme.contrastFailures()
        let summary = failures.map {
            "\($0.requirement.foreground) on \($0.requirement.background): "
                + "\(($0.measuredRatio * 100).rounded() / 100) < \($0.requirement.minimumRatio)"
        }
        #expect(failures.isEmpty, "\(theme.name): \(summary)")
    }
}

extension NookTheme: CustomTestStringConvertible {
    public var testDescription: String { name }
}
