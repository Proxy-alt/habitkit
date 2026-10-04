import Foundation

// MARK: - NookRGBA

/// An sRGB colour with straight (non-premultiplied) alpha, components in `0...1`.
///
/// Encodes to and decodes from a CSS-style hex string so theme JSON stays
/// human-editable. Contrast maths follows WCAG 2.2.
public struct NookRGBA: Hashable, Sendable {

    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    /// Creates a colour from components, clamping each to `0...1`.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
    }

    /// Creates an opaque colour from a 24-bit `0xRRGGBB` value.
    ///
    /// Used for compiled-in palettes, where a failable initialiser would
    /// force an unwrap at every call site.
    public init(rgb: UInt32) {
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    /// Parses `#RGB`, `#RRGGBB`, or `#RRGGBBAA`. The leading `#` is optional.
    ///
    /// Returns `nil` for any other length or for non-hex digits.
    public init?(hex: String) {
        var digits = Substring(hex.trimmingCharacters(in: .whitespacesAndNewlines))
        if digits.hasPrefix("#") { digits = digits.dropFirst() }
        guard digits.allSatisfy(\.isHexDigit) else { return nil }

        let expanded: String
        switch digits.count {
        case 3: expanded = digits.map { "\($0)\($0)" }.joined() + "ff"
        case 6: expanded = digits + "ff"
        case 8: expanded = String(digits)
        default: return nil
        }
        guard let value = UInt32(expanded, radix: 16) else { return nil }

        self.init(
            red: Double((value >> 24) & 0xFF) / 255,
            green: Double((value >> 16) & 0xFF) / 255,
            blue: Double((value >> 8) & 0xFF) / 255,
            alpha: Double(value & 0xFF) / 255
        )
    }

    /// Lowercase `#rrggbb`, or `#rrggbbaa` when not fully opaque.
    public var hexString: String {
        func byte(_ component: Double) -> String {
            String(format: "%02x", Int((component * 255).rounded()))
        }
        let rgb = "#" + byte(red) + byte(green) + byte(blue)
        return alpha < 1 ? rgb + byte(alpha) : rgb
    }

    // MARK: Contrast

    /// WCAG relative luminance of the colour, ignoring alpha.
    public var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /// Alpha-composites this colour over an opaque `background`.
    public func composited(over background: NookRGBA) -> NookRGBA {
        func mix(_ top: Double, _ bottom: Double) -> Double {
            top * alpha + bottom * (1 - alpha)
        }
        return NookRGBA(
            red: mix(red, background.red),
            green: mix(green, background.green),
            blue: mix(blue, background.blue)
        )
    }

    /// WCAG contrast ratio (`1...21`) of this colour drawn on `background`.
    ///
    /// Translucent foregrounds are composited over `background` first.
    public func contrastRatio(on background: NookRGBA) -> Double {
        let foreground = composited(over: background).relativeLuminance
        let backing = background.relativeLuminance
        return (max(foreground, backing) + 0.05) / (min(foreground, backing) + 0.05)
    }
}

// MARK: - Codable

extension NookRGBA: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let colour = NookRGBA(hex: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected #RGB, #RRGGBB, or #RRGGBBAA, found \"\(string)\""
            )
        }
        self = colour
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hexString)
    }
}
