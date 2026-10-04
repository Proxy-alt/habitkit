import NookCore
import SwiftUI
import Testing
@testable import NookUI

@Suite("NookColourStyle")
struct NookColourStyleTests {

    @Test("resolves each role against the theme in the environment", arguments: NookColour.allCases)
    func resolvesFromEnvironment(role: NookColour) {
        var environment = EnvironmentValues()
        environment.nookTheme = .latte
        #expect(NookColourStyle(role).resolve(in: environment) == NookTheme.latte.color(role))
    }

    @Test("falls back to Mocha when no theme is set")
    func defaultsToMocha() {
        #expect(NookColourStyle(.base).resolve(in: EnvironmentValues()) == NookTheme.mocha.color(.base))
    }

    @Test("converts components to an sRGB colour")
    func convertsToColor() {
        let colour = NookRGBA(red: 1, green: 0.5, blue: 0, alpha: 0.25)
        #expect(colour.swiftUIColor == Color(.sRGB, red: 1, green: 0.5, blue: 0, opacity: 0.25))
    }
}
