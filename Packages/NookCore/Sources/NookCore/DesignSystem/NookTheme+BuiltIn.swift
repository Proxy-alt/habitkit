// MARK: - Built-in themes

// Catppuccin (https://catppuccin.com), MIT licensed. Values mirror
// HabitNookUI/Sources/Themes/Built-in/catppuccin.json; NookThemeTests
// asserts they stay in sync.
public extension NookTheme {

    /// Catppuccin Latte, light.
    static let latte = NookTheme(
        id: "catppuccin-latte",
        name: "Latte",
        isDark: false,
        colors: NookPalette(
            base: NookRGBA(rgb: 0xEFF1F5),
            surface0: NookRGBA(rgb: 0xCCD0DA),
            surface1: NookRGBA(rgb: 0xBCC0CC),
            surface2: NookRGBA(rgb: 0xACB0BE),
            overlay0: NookRGBA(rgb: 0x9CA0B0),
            text: NookRGBA(rgb: 0x4C4F69),
            subtext: NookRGBA(rgb: 0x5C5F77),
            primary: NookRGBA(rgb: 0x8839EF),
            success: NookRGBA(rgb: 0x40A02B),
            warning: NookRGBA(rgb: 0xFE640B),
            danger: NookRGBA(rgb: 0xD20F39)
        )
    )

    /// Catppuccin Frappe, dark.
    static let frappe = NookTheme(
        id: "catppuccin-frappe",
        name: "Frapp\u{E9}",
        isDark: true,
        colors: NookPalette(
            base: NookRGBA(rgb: 0x303446),
            surface0: NookRGBA(rgb: 0x414559),
            surface1: NookRGBA(rgb: 0x51576D),
            surface2: NookRGBA(rgb: 0x626880),
            overlay0: NookRGBA(rgb: 0x737994),
            text: NookRGBA(rgb: 0xC6D0F5),
            subtext: NookRGBA(rgb: 0xB5BFE2),
            primary: NookRGBA(rgb: 0xCA9EE6),
            success: NookRGBA(rgb: 0xA6D189),
            warning: NookRGBA(rgb: 0xEF9F76),
            danger: NookRGBA(rgb: 0xE78284)
        )
    )

    /// Catppuccin Macchiato, dark.
    static let macchiato = NookTheme(
        id: "catppuccin-macchiato",
        name: "Macchiato",
        isDark: true,
        colors: NookPalette(
            base: NookRGBA(rgb: 0x24273A),
            surface0: NookRGBA(rgb: 0x363A4F),
            surface1: NookRGBA(rgb: 0x494D64),
            surface2: NookRGBA(rgb: 0x5B6078),
            overlay0: NookRGBA(rgb: 0x6E738D),
            text: NookRGBA(rgb: 0xCAD3F5),
            subtext: NookRGBA(rgb: 0xB8C0E0),
            primary: NookRGBA(rgb: 0xC6A0F6),
            success: NookRGBA(rgb: 0xA6DA95),
            warning: NookRGBA(rgb: 0xF5A97F),
            danger: NookRGBA(rgb: 0xED8796)
        )
    )

    /// Catppuccin Mocha, dark. The suite default.
    static let mocha = NookTheme(
        id: "catppuccin-mocha",
        name: "Mocha",
        isDark: true,
        colors: NookPalette(
            base: NookRGBA(rgb: 0x1E1E2E),
            surface0: NookRGBA(rgb: 0x313244),
            surface1: NookRGBA(rgb: 0x45475A),
            surface2: NookRGBA(rgb: 0x585B70),
            overlay0: NookRGBA(rgb: 0x6C7086),
            text: NookRGBA(rgb: 0xCDD6F4),
            subtext: NookRGBA(rgb: 0xBAC2DE),
            primary: NookRGBA(rgb: 0xCBA6F7),
            success: NookRGBA(rgb: 0xA6E3A1),
            warning: NookRGBA(rgb: 0xFAB387),
            danger: NookRGBA(rgb: 0xF38BA8)
        )
    )

    /// Every built-in theme, light first.
    static let builtIn: [NookTheme] = [.latte, .frappe, .macchiato, .mocha]
}
