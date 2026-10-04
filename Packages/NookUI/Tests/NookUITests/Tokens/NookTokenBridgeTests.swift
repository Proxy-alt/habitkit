import NookCore
import SwiftUI
import Testing
@testable import NookUI

@Suite("Token SwiftUI bridges")
struct NookTokenBridgeTests {

    @Test("fonts use Dynamic Type text styles")
    func fontsScale() {
        #expect(Font.nook(.headline) == .system(.headline, design: .rounded, weight: .semibold))
        #expect(Font.nook(.mono) == .system(.body, design: .monospaced, weight: .regular))
    }

    @Test("animations are springs, or crossfades under Reduce Motion")
    func animationsHonourReduceMotion() {
        #expect(NookAnimation.standard.swiftUIAnimation(reduceMotion: false) == .spring(duration: 0.35, bounce: 0.2))
        #expect(NookAnimation.slow.swiftUIAnimation(reduceMotion: true) == .easeInOut(duration: 0.2))
    }

    @Test("spacing and radius expose point values")
    func pointValues() {
        #expect(NookSpacing.md.value == 16)
        #expect(NookRadius.card.value == 12)
    }

    @Test("every text style maps to a distinct SwiftUI text style")
    func textStylesAreDistinct() {
        #expect(Set(NookTextStyle.allCases.map(\.swiftUITextStyle)).count == NookTextStyle.allCases.count)
    }
}

// Compile-time check that the call-site spellings in STYLE_GUIDE 4 resolve
// without type annotations.
private struct CallSiteSpellings: View {
    var body: some View {
        VStack(spacing: NookSpacing.sm.value) {
            Text(verbatim: "Title")
                .font(.nook(.headline))
                .foregroundStyle(.nook(.text))
            Label("Streak", nookSymbol: .flame)
                .nookIconSize(.sm)
        }
        .padding(.md)
        .padding(.horizontal, .lg)
        .background(.nook(.surface0), in: .nook(.card))
        .clipShape(.nook(.card))
        .nookAnimation(.quick, value: 0)
        .nookTheme(light: .latte, dark: .mocha)
    }
}
