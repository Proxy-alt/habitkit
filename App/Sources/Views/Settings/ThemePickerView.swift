import SwiftUI
import HabitKitUI

struct ThemePickerView: View {
    @Environment(HKThemeManager.self) private var themes
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: HKSpacing.sm) {
                        ForEach(themes.available) { theme in
                            ThemeCard(theme: theme, isSelected: theme.id == themes.current.id) {
                                themes.select(theme)
                            }
                        }
                    }
                    .padding(HKSpacing.md)
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
    @Environment(HKThemeManager.self) private var themes
    let theme: HKTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: HKSpacing.md) {
                ThemePreview(theme: theme)
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: HKRadius.sm))

                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text(theme.name)
                        .font(.hkHeadline)
                        .foregroundStyle(themes.current.textColor)
                    HStack(spacing: 4) {
                        Image(systemName: theme.isDark ? HKSymbol.moon : HKSymbol.sun)
                            .font(.hkCaption)
                        Text(theme.isDark ? "Dark" : "Light")
                            .font(.hkCaption)
                    }
                    .foregroundStyle(themes.current.subtextColor)

                    if let author = theme.author {
                        Text("@\(author)")
                            .font(.hkCaption)
                            .foregroundStyle(themes.current.subtextColor)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: HKSymbol.checkmark)
                        .foregroundStyle(themes.current.primaryColor)
                        .font(.title2)
                }
            }
            .padding(HKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: HKRadius.card)
                    .fill(themes.current.surface0Color)
                    .overlay(
                        RoundedRectangle(cornerRadius: HKRadius.card)
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
    let theme: HKTheme

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
