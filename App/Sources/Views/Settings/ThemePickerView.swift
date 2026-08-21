import SwiftUI
import HabitNookUI

struct ThemePickerView: View {
    @Environment(NookThemeManager.self) private var themes
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: NookSpacing.sm) {
                        ForEach(themes.available) { theme in
                            ThemeCard(theme: theme, isSelected: theme.id == themes.current.id) {
                                themes.select(theme)
                            }
                        }
                    }
                    .padding(NookSpacing.md)
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(themes.current.primaryColor)
                        .accessibilityLabel("Dismiss theme picker")
                }
            }
        }
    }
}

private struct ThemeCard: View {
    @Environment(NookThemeManager.self) private var themes
    let theme: NookTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: NookSpacing.md) {
                ThemePreview(theme: theme)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: NookRadius.sm))

                VStack(alignment: .leading, spacing: NookSpacing.xs) {
                    Text(theme.name)
                        .font(.nookHeadline)
                        .foregroundStyle(themes.current.textColor)
                    HStack(spacing: 4) {
                        Image(systemName: theme.isDark ? NookSymbol.moon : NookSymbol.sun)
                            .font(.nookCaption)
                        Text(theme.isDark ? "Dark" : "Light")
                            .font(.nookCaption)
                    }
                    .foregroundStyle(themes.current.subtextColor)

                    if let author = theme.author {
                        Text("@\(author)")
                            .font(.nookCaption)
                            .foregroundStyle(themes.current.subtextColor)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: NookSymbol.checkmark)
                        .foregroundStyle(themes.current.primaryColor)
                        .font(.title2)
                }
            }
            .padding(NookSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.card)
                    .fill(themes.current.surface0Color)
                    .overlay(
                        RoundedRectangle(cornerRadius: NookRadius.card)
                            .strokeBorder(
                                isSelected ? themes.current.primaryColor : Color.clear,
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
            theme.baseColor

            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.surface0Color)
                        .frame(width: 30, height: 10)
                    Spacer()
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: 10)
                }
                .padding(.horizontal, 6)

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.successColor)
                        .frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.surface0Color)
                        .frame(width: 40, height: 8)
                    Spacer()
                }
                .padding(.horizontal, 6)

                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.warningColor)
                        .frame(width: 8, height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.surface0Color)
                        .frame(width: 32, height: 8)
                    Spacer()
                }
                .padding(.horizontal, 6)
            }
        }
    }
}
