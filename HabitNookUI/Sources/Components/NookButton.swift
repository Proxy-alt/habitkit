import SwiftUI

// MARK: - NookButtonVariant

/// The visual style of an ``NookButton``.
public enum NookButtonVariant: Sendable {
    /// Filled background using the theme's primary colour.
    case primary
    /// Filled background using the theme's surface1 colour — subdued action.
    case secondary
    /// Filled background using the theme's danger colour — destructive action.
    case danger
    /// No background — label only with primary tint.
    case ghost
}

// MARK: - NookButton

/// A themed button that adapts to the active ``NookThemeManager``.
///
/// Usage:
/// ```swift
/// NookButton("Save", variant: .primary) { save() }
/// NookButton("Delete", variant: .danger, fullWidth: true) { delete() }
/// ```
public struct NookButton: View {

    // MARK: Dependencies

    @Environment(NookThemeManager.self) private var themeManager

    // MARK: Properties

    private let label: String
    private let variant: NookButtonVariant
    private let isFullWidth: Bool
    private let action: () -> Void

    // MARK: Init

    /// Creates a new button.
    ///
    /// - Parameters:
    ///   - label: The text displayed inside the button.
    ///   - variant: The visual style. Defaults to ``NookButtonVariant/primary``.
    ///   - fullWidth: When `true` the button stretches to fill available width. Defaults to `false`.
    ///   - action: The closure invoked when the button is tapped.
    public init(
        _ label: String,
        variant: NookButtonVariant = .primary,
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
                .font(NookFont.headline)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, NookSpacing.sm)
                .padding(.horizontal, NookSpacing.md)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: NookRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.card, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Computed colours

    private var theme: NookTheme { themeManager.current }

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

private struct NookButtonDisabledModifier: ViewModifier {
    @Environment(NookThemeManager.self) private var themeManager

    /// When `true` the button is visually dimmed and interaction is blocked.
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isDisabled)
            .overlay(
                isDisabled
                    ? RoundedRectangle(cornerRadius: NookRadius.card, style: .continuous)
                        .fill(themeManager.current.overlay0Color.opacity(0.5))
                    : nil
            )
            .allowsHitTesting(!isDisabled)
    }
}

public extension NookButton {
    /// Applies the standard disabled overlay and blocks interaction.
    ///
    /// - Parameter disabled: Pass `true` to disable the button. Defaults to `true`.
    func nookDisabled(_ disabled: Bool = true) -> some View {
        self.modifier(NookButtonDisabledModifier(isDisabled: disabled))
    }
}

// MARK: - Preview

#Preview("NookButton — all variants") {
    @Previewable @State var themeManager = NookThemeManager()

    VStack(spacing: NookSpacing.md) {
        NookButton("Primary Action", variant: .primary) {}
        NookButton("Secondary Action", variant: .secondary) {}
        NookButton("Danger Action", variant: .danger) {}
        NookButton("Ghost Action", variant: .ghost) {}
        NookButton("Full Width Primary", variant: .primary, fullWidth: true) {}
        NookButton("Disabled", variant: .primary) {}
            .nookDisabled()
    }
    .padding(NookSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
