import SwiftUI
import HabitKitCore
import HabitKitUI

struct SettingsView: View {
    @Environment(HKThemeManager.self) private var themes
    @AppStorage(DefaultsKeys.icloudSync) private var icloudSync = true
    @AppStorage(DefaultsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(DefaultsKeys.notificationSound) private var notificationSound = "default"
    @State private var showThemePicker = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                themes.current.baseColor.ignoresSafeArea()

                List {
                    Section("Appearance") {
                        Button {
                            showThemePicker = true
                        } label: {
                            HStack {
                                Label("Theme", systemImage: HKSymbol.paintpalette)
                                    .foregroundStyle(themes.current.textColor)
                                Spacer()
                                Text(themes.current.name)
                                    .font(.hkBody)
                                    .foregroundStyle(themes.current.subtextColor)
                                Image(systemName: HKSymbol.chevronRight)
                                    .font(.hkCaption)
                                    .foregroundStyle(themes.current.overlay0Color)
                            }
                        }
                        .accessibilityLabel("Theme, current: \(themes.current.name)")
                    }

                    Section("Sync") {
                        Toggle(isOn: $icloudSync) {
                            Label("iCloud Sync", systemImage: HKSymbol.icloud)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .tint(themes.current.primaryColor)
                        .accessibilityLabel("iCloud Sync")
                    }

                    Section("Feedback") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: HKSymbol.handTap)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .tint(themes.current.primaryColor)
                        .accessibilityLabel("Haptics")
                    }

                    Section("Notifications") {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            Label("Notification Settings", systemImage: HKSymbol.bell)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .accessibilityLabel("Notification Settings")
                    }

                    Section("Data") {
                        NavigationLink {
                            DataExportView()
                        } label: {
                            Label("Export Data", systemImage: HKSymbol.squareArrowUp)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .accessibilityLabel("Export Data")

                        NavigationLink {
                            HealthKitSettingsView()
                        } label: {
                            Label("HealthKit", systemImage: HKSymbol.heart)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .accessibilityLabel("HealthKit")
                    }

                    Section("Community") {
                        NavigationLink {
                            CommunityThemeGalleryView()
                        } label: {
                            Label("Theme Gallery", systemImage: HKSymbol.sparkles)
                                .foregroundStyle(themes.current.textColor)
                        }
                        .accessibilityLabel("Theme Gallery")
                    }

                    Section("About") {
                        HStack {
                            Label("Version", systemImage: HKSymbol.infoCircle)
                                .foregroundStyle(themes.current.textColor)
                            Spacer()
                            Text(appVersion)
                                .font(.hkMono)
                                .foregroundStyle(themes.current.subtextColor)
                        }
                        .accessibilityLabel("Version \(appVersion)")

                        if let githubURL = URL(string: "https://github.com/habitkit/habitkit") {
                            Link(destination: githubURL) {
                                Label("GitHub", systemImage: HKSymbol.link)
                                    .foregroundStyle(themes.current.primaryColor)
                            }
                            .accessibilityLabel("GitHub repository")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Reset All Data", systemImage: HKSymbol.trash)
                                .foregroundStyle(themes.current.dangerColor)
                        }
                        .accessibilityLabel("Reset All Data")
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showThemePicker) {
                ThemePickerView()
            }
            .confirmationDialog("Reset All Data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) {
                    UserDefaults.standard.set(true, forKey: "hk_reset_flag")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all habits and completions. This cannot be undone.")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private struct NotificationSettingsView: View {
    @Environment(HKThemeManager.self) private var themes

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()
            VStack {
                Text("Notification settings are managed in the iOS Settings app.")
                    .font(.hkBody)
                    .foregroundStyle(themes.current.subtextColor)
                    .multilineTextAlignment(.center)
                    .padding(HKSpacing.xl)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(themes.current.primaryColor)
                .accessibilityLabel("Open iOS Settings")
            }
        }
        .navigationTitle("Notifications")
    }
}

private struct DataExportView: View {
    @Environment(HKThemeManager.self) private var themes

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()
            VStack(spacing: HKSpacing.lg) {
                HKButton("Export as JSON", variant: .primary) { }
                HKButton("Export as CSV", variant: .secondary) { }
                HKButton("Export Full Archive (.habitarchive)", variant: .secondary) { }
            }
            .padding(HKSpacing.xl)
        }
        .navigationTitle("Export Data")
    }
}

private struct HealthKitSettingsView: View {
    @Environment(HKThemeManager.self) private var themes

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()
            VStack(spacing: HKSpacing.md) {
                Image(systemName: HKSymbol.heart)
                    .font(HKIconSize.lg)
                    .foregroundStyle(themes.current.dangerColor)
                Text("HealthKit permissions are managed per-habit when you create or edit a habit.")
                    .font(.hkBody)
                    .foregroundStyle(themes.current.subtextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(HKSpacing.xl)
        }
        .navigationTitle("HealthKit")
    }
}

private struct CommunityThemeGalleryView: View {
    @Environment(HKThemeManager.self) private var themes

    var body: some View {
        ZStack {
            themes.current.baseColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: HKSpacing.sm) {
                    ForEach(themes.available.filter { $0.author != nil }) { theme in
                        HKCard {
                            HStack {
                                VStack(alignment: .leading, spacing: HKSpacing.xs) {
                                    Text(theme.name)
                                        .font(.hkHeadline)
                                        .foregroundStyle(themes.current.textColor)
                                    if let author = theme.author {
                                        Text("by @\(author)")
                                            .font(.hkCaption)
                                            .foregroundStyle(themes.current.subtextColor)
                                    }
                                }
                                Spacer()
                                ThemeColorDots(theme: theme)
                                HKButton("Use", variant: .primary) {
                                    themes.select(theme)
                                }
                            }
                        }
                    }
                }
                .padding(HKSpacing.md)
            }
        }
        .navigationTitle("Theme Gallery")
    }
}

private struct ThemeColorDots: View {
    let theme: HKTheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach([theme.primaryColor, theme.successColor, theme.warningColor, theme.dangerColor], id: \.self) { color in
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
    }
}
