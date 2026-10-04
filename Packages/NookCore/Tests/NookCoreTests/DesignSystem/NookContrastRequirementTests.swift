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

    @Test("dark built-in themes meet the suite requirements", arguments: [NookTheme.frappe, .macchiato, .mocha])
    func darkBuiltInsPass(theme: NookTheme) {
        expectNoFailures(in: theme)
    }

    // Latte fails text on surface1, subtext on surface0, success on base and
    // surface0, and warning on base. Proposed palette fix: nookui-design-doc.md 4.2.
    // Remove withKnownIssue once the fix lands; Swift Testing will then flag
    // the known issue as unexpectedly resolved.
    @Test("Latte meets the suite requirements")
    func lattePasses() {
        withKnownIssue("Latte contrast shortfalls, nookui-design-doc.md 4.2") {
            expectNoFailures(in: .latte)
        }
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
