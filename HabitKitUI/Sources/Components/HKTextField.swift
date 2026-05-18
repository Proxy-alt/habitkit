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
                    .font(.hkCaption)
                    .foregroundStyle(themeManager.current.subtextColor)
            }

            TextField(placeholder, text: $text)
                .font(.hkBody)
                .foregroundStyle(themeManager.current.textColor)
                .tint(themeManager.current.primaryColor)
                .focused($isFocused)
                .padding(.vertical, HKSpacing.sm)
                .padding(.horizontal, HKSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(themeManager.current.surface2Color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isFocused
                                ? themeManager.current.primaryColor
                                : themeManager.current.overlay0Color.opacity(0.5),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}
