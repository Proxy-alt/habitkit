import NookCore
import SwiftUI

// MARK: - NookTextField

/// A theme-styled text field with an optional label above the input.
///
/// Usage:
/// ```swift
/// NookTextField("Habit name", text: $name, label: "Name")
/// ```
public struct NookTextField: View {

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
        VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
            if let label {
                Text(label)
                    .font(.nook(.caption))
                    .foregroundStyle(.nook(.subtext))
            }

            TextField(placeholder, text: $text)
                .font(.nook(.body))
                .foregroundStyle(.nook(.text))
                .tint(NookColourStyle(.primary))
                .focused($isFocused)
                .padding(.vertical, .sm)
                .padding(.horizontal, .md)
                .background(
                    RoundedRectangle.nook(.md)
                        .fill(.nook(.surface2))
                )
                .overlay(
                    RoundedRectangle.nook(.md)
                        .stroke(
                            isFocused
                                ? AnyShapeStyle(.nook(.primary))
                                : AnyShapeStyle(.nook(.overlay0).opacity(0.5)),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .nookAnimation(.quick, value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview("NookTextField -- empty and filled") {
    @Previewable @State var emptyText = ""
    @Previewable @State var filledText = "Morning Run"

    VStack(spacing: NookSpacing.lg.value) {
        NookTextField("Enter habit name...", text: $emptyText, label: "Habit Name")
        NookTextField("No label, empty", text: $emptyText)
        NookTextField("Enter habit name...", text: $filledText, label: "Filled Field")
    }
    .padding(.md)
    .background(.nook(.base))
    .nookTheme(.mocha)
}
