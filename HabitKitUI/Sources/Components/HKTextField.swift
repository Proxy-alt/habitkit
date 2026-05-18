import SwiftUI

// MARK: - HKTextField

/// A theme-styled text field with an optional label above the input.
///
/// Usage:
/// ```swift
/// HKTextField("Habit name", text: $name, label: "Name")
/// ```
public struct HKTextField: View {

    // MARK: Dependencies

    @Environment(HKThemeManager.self) private var themeManager

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
        VStack(alignment: .leading, spacing: HKSpacing.xs) {
            if let label {
                Text(label)
                    .font(HKFont.caption)
                    .foregroundStyle(themeManager.current.subtextColor)
            }

            TextField(placeholder, text: $text)
                .font(HKFont.body)
                .foregroundStyle(themeManager.current.textColor)
                .tint(themeManager.current.primaryColor)
                .focused($isFocused)
                .padding(.vertical, HKSpacing.sm)
                .padding(.horizontal, HKSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: HKRadius.md, style: .continuous)
                        .fill(themeManager.current.surface2Color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HKRadius.md, style: .continuous)
                        .stroke(
                            isFocused
                                ? themeManager.current.primaryColor
                                : themeManager.current.overlay0Color.opacity(0.5),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .animation(HKAnimation.quick, value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview("HKTextField — empty and filled") {
    @Previewable @State var themeManager = HKThemeManager()
    @Previewable @State var emptyText = ""
    @Previewable @State var filledText = "Morning Run"

    VStack(spacing: HKSpacing.lg) {
        HKTextField("Enter habit name…", text: $emptyText, label: "Habit Name")
        HKTextField("No label, empty", text: $emptyText)
        HKTextField("Enter habit name…", text: $filledText, label: "Filled Field")
    }
    .padding(HKSpacing.md)
    .background(themeManager.current.baseColor)
    .environment(themeManager)
}
