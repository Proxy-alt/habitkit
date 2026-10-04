// MARK: - NookPalette

/// The resolved colour for every ``NookColour`` role in one theme.
///
/// The coding keys match the `colors` object in theme JSON, so existing
/// HabitNookUI theme files decode unchanged.
public struct NookPalette: Codable, Hashable, Sendable {

    public let base: NookRGBA
    public let surface0: NookRGBA
    public let surface1: NookRGBA
    public let surface2: NookRGBA
    public let overlay0: NookRGBA
    public let text: NookRGBA
    public let subtext: NookRGBA
    public let primary: NookRGBA
    public let success: NookRGBA
    public let warning: NookRGBA
    public let danger: NookRGBA

    public init(
        base: NookRGBA,
        surface0: NookRGBA,
        surface1: NookRGBA,
        surface2: NookRGBA,
        overlay0: NookRGBA,
        text: NookRGBA,
        subtext: NookRGBA,
        primary: NookRGBA,
        success: NookRGBA,
        warning: NookRGBA,
        danger: NookRGBA
    ) {
        self.base = base
        self.surface0 = surface0
        self.surface1 = surface1
        self.surface2 = surface2
        self.overlay0 = overlay0
        self.text = text
        self.subtext = subtext
        self.primary = primary
        self.success = success
        self.warning = warning
        self.danger = danger
    }

    /// The colour assigned to `role`.
    public subscript(role: NookColour) -> NookRGBA {
        switch role {
        case .base: base
        case .surface0: surface0
        case .surface1: surface1
        case .surface2: surface2
        case .overlay0: overlay0
        case .text: text
        case .subtext: subtext
        case .primary: primary
        case .success: success
        case .warning: warning
        case .danger: danger
        }
    }
}
