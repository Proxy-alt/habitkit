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
                .font(.hkHeadline)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, HKSpacing.sm)
                .padding(.horizontal, HKSpacing.md)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
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
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isDisabled)
            .overlay(
                isDisabled
                    ? RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeManager.current.overlay0Color.opacity(0.5))
                    : nil
            )
            .allowsHitTesting(!isDisabled)
    }
}

public extension HKButton {
    /// Applies the standard disabled overlay and blocks interaction.
    func hkDisabled(_ disabled: Bool = true) -> some View {
        self.modifier(HKButtonDisabledModifier(isDisabled: disabled))
    }
}
