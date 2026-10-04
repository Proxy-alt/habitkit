import Foundation
import Testing
@testable import NookCore

@Suite("NookRGBA")
struct NookRGBATests {

    @Test("parses six-digit hex with or without a leading #", arguments: ["#1e1e2e", "1E1E2E", " #1e1e2e\n"])
    func parsesSixDigit(input: String) throws {
        let colour = try #require(NookRGBA(hex: input))
        #expect(colour == NookRGBA(rgb: 0x1E1E2E))
        #expect(colour.alpha == 1)
    }

    @Test("expands three-digit shorthand")
    func expandsShorthand() {
        #expect(NookRGBA(hex: "#fa0") == NookRGBA(rgb: 0xFFAA00))
    }

    @Test("reads alpha from the last byte of eight-digit hex")
    func readsAlpha() throws {
        let colour = try #require(NookRGBA(hex: "#00000080"))
        #expect(abs(colour.alpha - 128.0 / 255) < 0.0001)
    }

    @Test("rejects malformed hex", arguments: ["", "#", "#12", "#12345", "#1234567", "#gggggg", "#+12345"])
    func rejectsMalformed(input: String) {
        #expect(NookRGBA(hex: input) == nil)
    }

    @Test("round-trips through hexString")
    func roundTrips() {
        #expect(NookRGBA(rgb: 0xCBA6F7).hexString == "#cba6f7")
        #expect(NookRGBA(hex: "#cba6f780")?.hexString == "#cba6f780")
    }

    @Test("black on white has the maximum contrast ratio of 21")
    func maximumContrast() {
        let ratio = NookRGBA(rgb: 0x000000).contrastRatio(on: NookRGBA(rgb: 0xFFFFFF))
        #expect(abs(ratio - 21) < 0.001)
    }

    @Test("contrast ratio is symmetric")
    func symmetricContrast() {
        let a = NookRGBA(rgb: 0x8839EF)
        let b = NookRGBA(rgb: 0xEFF1F5)
        #expect(abs(a.contrastRatio(on: b) - b.contrastRatio(on: a)) < 0.0001)
    }

    @Test("a fully transparent foreground has no contrast")
    func transparentForeground() {
        let clear = NookRGBA(red: 0, green: 0, blue: 0, alpha: 0)
        #expect(abs(clear.contrastRatio(on: NookRGBA(rgb: 0xFFFFFF)) - 1) < 0.0001)
    }

    @Test("decodes from a JSON string and rejects bad values")
    func codable() throws {
        let decoded = try JSONDecoder().decode([NookRGBA].self, from: Data(##"["#ffffff"]"##.utf8))
        #expect(decoded == [NookRGBA(rgb: 0xFFFFFF)])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([NookRGBA].self, from: Data(#"["white"]"#.utf8))
        }
    }
}
