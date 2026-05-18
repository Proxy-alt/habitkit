import SwiftUI

// MARK: - HKButtonVariant

/// The visual style of an ``HKButton``.
public enum HKButtonVariant: Sendable {
    /// Filled background using the theme's primary colour.
    case primary
    /// Filled background using the theme's surface1 colour — subdued action.
    case secondary
    /// Filled background using the theme's danger colour — destructive action.
    case danger
    /// No background — label only with primary tint.
    case ghost
}

// MARK: - HKButton

/// A themed button that adapts to the active ``HKThemeManager``.
///
/// Usage:
/// ```swift
/// HKButton("Save", variant: .primary) { save() }
/// HKButton("Delete", variant: .danger, fullWidth: true) { delete() }
/// ```
public struct HKButton: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

    // MARK: Properties

    private let label: String
    private let variant: HKButtonVariant
    private let isFullWidth: Bool
    private let action: () -> Void

    // MARK: Init

    /// Creates a new button.
    ///
    /// - Parameters:
    ///   - label: The text displayed inside the button.
    ///   - variant: The visual style. Defaults to ``HKButtonVariant/primary``.
    ///   - fullWidth: When `true` the button stretches to fill available width. Defaults to `false`.
    ///   - action: The closure invoked when the button is tapped.
    public init(
        _ label: String,
        variant: HKButtonVariant = .primary,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label       = label
        self.variant     = variant
        self.isFullWidth = fullWidth
        self.action      = action
    }

    // MARK: Body

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(HKFont.headline)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, HKSpacing.sm)
                .padding(.horizontal, HKSpacing.md)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: HKRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: HKRadius.card, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Computed colours

    private var theme: HKTheme { themeManager.current }

    private var foregroundColor: Color {
        switch variant {
        case .primary:   return theme.baseColor
        case .secondary: return theme.textColor
        case .danger:    return theme.baseColor
        case .ghost:     return theme.primaryColor
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:   return theme.primaryColor
        case .secondary: return theme.surface1Color
        case .danger:    return theme.dangerColor
        case .ghost:     return .clear
        }
    }

    private var borderColor: Color {
        switch variant {
        case .ghost:  return theme.primaryColor.opacity(0.6)
        default:      return .clear
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .ghost: return 1
        default:     return 0
        }
    }
}

// MARK: - Disabled state modifier

private struct HKButtonDisabledModifier: ViewModifier {
    @Environment(HKThemeManager.self) private var themeManager

    /// When `true` the button is visually dimmed and interaction is blocked.
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isDisabled)
            .overlay(
                isDisabled
                    ? RoundedRectangle(cornerRadius: HKRadius.card, style: .continuous)
                        .fill(themeManager.current.overlay0Color.opacity(0.5))
                    : nil
            )
            .allowsHitTesting(!isDisabled)
    }
}

public extension HKButton {
    /// Applies the standard disabled overlay and blocks interaction.
    ///
    /// - Parameter disabled: Pass `true` to disable the button. Defaults to `true`.
    func hkDisabled(_ disabled: Bool = true) -> some View {
        self.modifier(HKButtonDisabledModifier(isDisabled: disabled))
    }
}

// MARK: - Preview

#Preview("HKButton — all variants") {
    @Previewable @State var themeManager = HKThemeManager()

    VStack(spacing: HKSpacing.md) {
        HKButton("Primary Action", variant: .primary) {}
        HKButton("Secondary Action", variant: .secondary) {}
        HKButton("Danger Action", variant: .danger) {}
        HKButton("Ghost Action", variant: .ghost) {}
        HKButton("Full Width Primary", variant: .primary, fullWidth: true) {}
        HKButton("Disabled", variant: .primary) {}
            .hkDisabled()
    }
    .padding(HKSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
