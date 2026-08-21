import SwiftUI

// MARK: - NookTextField

/// A theme-styled text field with an optional label above the input.
///
/// Usage:
/// ```swift
/// NookTextField("Habit name", text: $name, label: "Name")
/// ```
public struct NookTextField: View {

    // MARK: Dependencies

    @Environment(NookThemeManager.self) private var themeManager

    // MARK: Properties

    private let placeholder: String
    private let label: String?
    @Binding private var text: String

    @FocusState private var isFocused: Bool

    // MARK: Init

    /// Creates a new themed text field.
    ///
    /// - Parameters:
    ///   - placeholder: The placeholder string shown when the field is empty.
    ///   - text: A binding to the field's string value.
    ///   - label: An optional caption label rendered above the field.
    public init(
        _ placeholder: String,
        text: Binding<String>,
        label: String? = nil
    ) {
        self.placeholder = placeholder
        self._text       = text
        self.label       = label
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: NookSpacing.xs) {
            if let label {
                Text(label)
                    .font(NookFont.caption)
                    .foregroundStyle(themeManager.current.subtextColor)
            }

            TextField(placeholder, text: $text)
                .font(NookFont.body)
                .foregroundStyle(themeManager.current.textColor)
                .tint(themeManager.current.primaryColor)
                .focused($isFocused)
                .padding(.vertical, NookSpacing.sm)
                .padding(.horizontal, NookSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .fill(themeManager.current.surface2Color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .stroke(
                            isFocused
                                ? themeManager.current.primaryColor
                                : themeManager.current.overlay0Color.opacity(0.5),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .animation(NookAnimation.quick, value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview("NookTextField — empty and filled") {
    @Previewable @State var themeManager = NookThemeManager()
    @Previewable @State var emptyText = ""
    @Previewable @State var filledText = "Morning Run"

    VStack(spacing: NookSpacing.lg) {
        NookTextField("Enter habit name…", text: $emptyText, label: "Habit Name")
        NookTextField("No label, empty", text: $emptyText)
        NookTextField("Enter habit name…", text: $filledText, label: "Filled Field")
    }
    .padding(NookSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
