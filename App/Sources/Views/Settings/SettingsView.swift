import SwiftUI
import HabitNookCore
import HabitNookUI
import NookCore
import NookUI

struct SettingsView: View {
    @Environment(NookThemeManager.self) private var themes
    @AppStorage(DefaultsKeys.iCloudSync) private var icloudSync = true
    @AppStorage(DefaultsKeys.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(DefaultsKeys.notificationSound) private var notificationSound = "default"
    @State private var showThemePicker = false
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(.nook(.base)).ignoresSafeArea()

                List {
                    Section("Appearance") {
                        Button {
                            showThemePicker = true
                        } label: {
                            HStack {
                                Label("Theme", nookSymbol: .paintpalette)
                                    .foregroundStyle(.nook(.text))
                                Spacer()
                                Text(themes.current.name)
                                    .font(.nook(.body))
                                    .foregroundStyle(.nook(.subtext))
                                Image(nookSymbol: .chevronRight)
                                    .font(.nook(.caption))
                                    .foregroundStyle(.nook(.overlay0))
                            }
                        }
                        .accessibilityLabel("Theme, current: \(themes.current.name)")
                    }

                    Section("Sync") {
                        Toggle(isOn: $icloudSync) {
                            Label("iCloud Sync", nookSymbol: .icloud)
                                .foregroundStyle(.nook(.text))
                        }
                        .tint(NookColourStyle(.primary))
                        .accessibilityLabel("iCloud Sync")
                    }

                    Section("Feedback") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", nookSymbol: .handTap)
                                .foregroundStyle(.nook(.text))
                        }
                        .tint(NookColourStyle(.primary))
                        .accessibilityLabel("Haptics")
                    }

                    Section("Notifications") {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            Label("Notification Settings", nookSymbol: .bell)
                                .foregroundStyle(.nook(.text))
                        }
                        .accessibilityLabel("Notification Settings")
                    }

                    Section("Data") {
                        NavigationLink {
                            DataExportView()
                        } label: {
                            Label("Export Data", nookSymbol: .squareArrowUp)
                                .foregroundStyle(.nook(.text))
                        }
                        .accessibilityLabel("Export Data")

                        NavigationLink {
                            HealthKitSettingsView()
                        } label: {
                            Label("HealthKit", nookSymbol: .heart)
                                .foregroundStyle(.nook(.text))
                        }
                        .accessibilityLabel("HealthKit")
                    }

                    Section("Community") {
                        NavigationLink {
                            CommunityThemeGalleryView()
                        } label: {
                            Label("Theme Gallery", nookSymbol: .sparkles)
                                .foregroundStyle(.nook(.text))
                        }
                        .accessibilityLabel("Theme Gallery")
                    }

                    Section("About") {
                        HStack {
                            Label("Version", nookSymbol: .infoCircle)
                                .foregroundStyle(.nook(.text))
                            Spacer()
                            Text(appVersion)
                                .font(.nook(.mono))
                                .foregroundStyle(.nook(.subtext))
                        }
                        .accessibilityLabel("Version \(appVersion)")

                        if let githubURL = URL(string: "https://github.com/Proxy-alt/habitkit") {
                            Link(destination: githubURL) {
                                Label("GitHub", nookSymbol: .link)
                                    .foregroundStyle(.nook(.primary))
                            }
                            .accessibilityLabel("GitHub repository")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Reset All Data", nookSymbol: .trash)
                                .foregroundStyle(.nook(.danger))
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

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base)).ignoresSafeArea()
            VStack {
                Text("Notification settings are managed in the iOS Settings app.")
                    .font(.nook(.body))
                    .foregroundStyle(.nook(.subtext))
                    .multilineTextAlignment(.center)
                    .padding(.xl)

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(NookColourStyle(.primary))
                .accessibilityLabel("Open iOS Settings")
            }
        }
        .navigationTitle("Notifications")
    }
}

private struct DataExportView: View {

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base)).ignoresSafeArea()
            VStack(spacing: NookSpacing.lg.value) {
                NookButton("Export as JSON", variant: .primary) { }
                NookButton("Export as CSV", variant: .secondary) { }
                NookButton("Export Full Archive (.habitarchive)", variant: .secondary) { }
            }
            .padding(.xl)
        }
        .navigationTitle("Export Data")
    }
}

private struct HealthKitSettingsView: View {

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base)).ignoresSafeArea()
            VStack(spacing: NookSpacing.md.value) {
                Image(nookSymbol: .heart)
                    .nookIconSize(.lg)
                    .foregroundStyle(.nook(.danger))
                Text("HealthKit permissions are managed per-habit when you create or edit a habit.")
                    .font(.nook(.body))
                    .foregroundStyle(.nook(.subtext))
                    .multilineTextAlignment(.center)
            }
            .padding(.xl)
        }
        .navigationTitle("HealthKit")
    }
}

private struct CommunityThemeGalleryView: View {
    @Environment(NookThemeManager.self) private var themes

    var body: some View {
        ZStack {
            Rectangle().fill(.nook(.base)).ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: NookSpacing.sm.value) {
                    ForEach(themes.available.filter { $0.author != nil }) { theme in
                        NookCard {
                            HStack {
                                VStack(alignment: .leading, spacing: NookSpacing.xs.value) {
                                    Text(theme.name)
                                        .font(.nook(.headline))
                                        .foregroundStyle(.nook(.text))
                                    if let author = theme.author {
                                        Text("by @\(author)")
                                            .font(.nook(.caption))
                                            .foregroundStyle(.nook(.subtext))
                                    }
                                }
                                Spacer()
                                ThemeColorDots(theme: theme)
                                NookButton("Use", variant: .primary) {
                                    themes.select(theme)
                                }
                            }
                        }
                    }
                }
                .padding(.md)
            }
        }
        .navigationTitle("Theme Gallery")
    }
}

private struct ThemeColorDots: View {
    let theme: NookTheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach([NookColour.primary, .success, .warning, .danger], id: \.self) { role in
                Circle().fill(theme.color(role)).frame(width: 10, height: 10)
            }
        }
    }
}
