import NookCore
import SwiftUI

// MARK: - NookButtonVariant

/// The visual style of an ``NookButton``.
public enum NookButtonVariant: Sendable {
    /// Filled background using the theme's primary colour.
    case primary
    /// Filled background using the theme's surface1 colour -- subdued action.
    case secondary
    /// Filled background using the theme's danger colour -- destructive action.
    case danger
    /// No background -- label only with primary tint.
    case ghost
}

// MARK: - NookButton

/// A themed button that resolves its colours from the theme in the environment.
///
/// Usage:
/// ```swift
/// NookButton("Save", variant: .primary) { save() }
/// NookButton("Delete", variant: .danger, fullWidth: true) { delete() }
/// ```
public struct NookButton: View {

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
                .font(.nook(.headline))
                .foregroundStyle(.nook(foregroundRole))
                .padding(.vertical, .sm)
                .padding(.horizontal, .md)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .background(backgroundStyle, in: .nook(.card))
                .overlay(
                    RoundedRectangle.nook(.card)
                        .stroke(borderStyle, lineWidth: borderWidth)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Computed styles

    private var foregroundRole: NookColour {
        switch variant {
        case .primary:   return .base
        case .secondary: return .text
        case .danger:    return .base
        case .ghost:     return .primary
        }
    }

    private var backgroundStyle: AnyShapeStyle {
        switch variant {
        case .primary:   return AnyShapeStyle(.nook(.primary))
        case .secondary: return AnyShapeStyle(.nook(.surface1))
        case .danger:    return AnyShapeStyle(.nook(.danger))
        case .ghost:     return AnyShapeStyle(.clear)
        }
    }

    private var borderStyle: AnyShapeStyle {
        switch variant {
        case .ghost:  return AnyShapeStyle(.nook(.primary).opacity(0.6))
        default:      return AnyShapeStyle(.clear)
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
    /// When `true` the button is visually dimmed and interaction is blocked.
    let isDisabled: Bool

    func body(content: Content) -> some View {
        content
            .disabled(isDisabled)
            .overlay(
                isDisabled
                    ? RoundedRectangle.nook(.card)
                        .fill(.nook(.overlay0).opacity(0.5))
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

#Preview("NookButton -- all variants") {
    VStack(spacing: NookSpacing.md.value) {
        NookButton("Primary Action", variant: .primary) {}
        NookButton("Secondary Action", variant: .secondary) {}
        NookButton("Danger Action", variant: .danger) {}
        NookButton("Ghost Action", variant: .ghost) {}
        NookButton("Full Width Primary", variant: .primary, fullWidth: true) {}
        NookButton("Disabled", variant: .primary) {}
            .nookDisabled()
    }
    .padding(.md)
    .background(.nook(.base))
    .nookTheme(.mocha)
}
