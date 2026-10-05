import SwiftUI
import HabitNookUI
import NookCore
import NookUI

struct ThemePickerView: View {
    @Environment(NookThemeManager.self) private var themes
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(.nook(.base)).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: NookSpacing.sm.value) {
                        ForEach(themes.available) { theme in
                            ThemeCard(theme: theme, isSelected: theme.id == themes.current.id) {
                                themes.select(theme)
                            }
                        }
                    }
                    .padding(.md)
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.nook(.primary))
                        .accessibilityLabel("Dismiss theme picker")
                }
            }
        }
    }
}

private struct ThemeCard: View {
    let theme: NookTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: NookSpacing.md.value) {
                ThemePreview(theme: theme)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle.nook(.sm))

                VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
                    Text(theme.name)
                        .font(.nook(.headline))
                        .foregroundStyle(.nook(.text))
                    HStack(spacing: 4) {
                        Image(nookSymbol: theme.isDark ? .moon : .sun)
                            .font(.nook(.caption))
                        Text(theme.isDark ? "Dark" : "Light")
                            .font(.nook(.caption))
                    }
                    .foregroundStyle(.nook(.subtext))

                    if let author = theme.author {
                        Text("@\(author)")
                            .font(.nook(.caption))
                            .foregroundStyle(.nook(.subtext))
                    }
                }

                Spacer()

                if isSelected {
                    Image(nookSymbol: .checkmark)
                        .foregroundStyle(.nook(.primary))
                        .font(.title2)
                }
            }
            .padding(.md)
            .background(
                RoundedRectangle.nook(.card)
                    .fill(.nook(.surface0))
                    .overlay(
                        RoundedRectangle.nook(.card)
                            .strokeBorder(
                                .nook(.primary).opacity(isSelected ? 1 : 0),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(theme.name) theme\(isSelected ? ", currently selected" : "")")
    }
}

private struct ThemePreview: View {
    let theme: NookTheme

    var body: some View {
        ZStack {
            theme.color(.base)

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(.surface0))
                        .frame(width: 30, height: 10)
                    Spacer()
                    Circle()
                        .fill(theme.color(.primary))
                        .frame(width: 10)
                }
                .padding(.horizontal, 6)

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(.success))
                        .frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(.surface0))
                        .frame(width: 40, height: 8)
                    Spacer()
                }
                .padding(.horizontal, 6)

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(.warning))
                        .frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.color(.surface0))
                        .frame(width: 32, height: 8)
                    Spacer()
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
