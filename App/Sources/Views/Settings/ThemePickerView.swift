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
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                    Text(theme.name)
                        .font(.hkHeadline)
                        .foregroundStyle(themes.current.textColor)
                    HStack(spacing: 4) {
                        Image(systemName: theme.isDark ? "moon.fill" : "sun.max.fill")
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
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themes.current.primaryColor)
                        .font(.title2)
                }
            }
            .padding(HKSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themes.current.surface0Color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? themes.current.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
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
