import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    private var theme: Theme { settings.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            themeSection
            Divider()
            mascotSection
            Divider()
            behaviourSection
        }
        .padding(22)
        .frame(width: 360)
        .background(theme.wash.opacity(0.25))
        .onAppear { launchAtLogin = LaunchAtLogin.isEnabled }
    }

    // MARK: Theme

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Theme")
            HStack(spacing: 10) {
                ForEach(Theme.allCases) { candidate in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.theme = candidate
                        }
                    } label: {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(candidate.wash)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(candidate.accent.opacity(0.6), lineWidth: 1))
                                if settings.theme == candidate {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .black, design: .rounded))
                                        .foregroundColor(candidate.ink)
                                }
                            }
                            .overlay(
                                Circle()
                                    .strokeBorder(candidate.accent, lineWidth: settings.theme == candidate ? 2 : 0)
                                    .frame(width: 37, height: 37)
                            )
                            Text(candidate.displayName)
                                .font(Font2.rounded(10, .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 66)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Mascot

    private var mascotSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionTitle("Mascot")
            HStack(spacing: 10) {
                ForEach(Mascot.allCases) { candidate in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            settings.mascot = candidate
                        }
                    } label: {
                        VStack(spacing: 6) {
                            MascotView(mascot: candidate, state: .idle, theme: theme, size: 34)
                                .frame(width: 34, height: 34)
                                .padding(7)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(settings.mascot == candidate
                                              ? theme.wash.opacity(0.9)
                                              : Color.primary.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(theme.accent,
                                                      lineWidth: settings.mascot == candidate ? 2 : 0)
                                )
                            Text(candidate.displayName)
                                .font(Font2.rounded(10, .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 76)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Behaviour

    private var behaviourSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Behaviour")

            settingRow("Show/hide shortcut") {
                HotKeyField(combo: $settings.hotKey, theme: theme)
            }

            settingRow("Pop sound on complete") {
                Toggle("", isOn: $settings.soundEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            settingRow("Streak badge") {
                Toggle("", isOn: $settings.showStreak)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            settingRow("Launch at login") {
                Toggle("", isOn: Binding(
                    get: { launchAtLogin },
                    set: { launchAtLogin = LaunchAtLogin.set($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            HStack {
                Button("Clear “done today”") {
                    withAnimation { store.clearDoneToday() }
                }
                .disabled(store.doneTodayItems.isEmpty)

                Spacer()

                Button("Quit Puff") { NSApp.terminate(nil) }
            }
            .font(Font2.rounded(12, .medium))
            .padding(.top, 2)
        }
    }

    // MARK: Bits

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Font2.rounded(10, .bold))
            .kerning(0.8)
            .foregroundColor(.secondary)
    }

    private func settingRow<Content: View>(_ label: String,
                                           @ViewBuilder control: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(Font2.rounded(12.5, .medium))
            Spacer()
            control()
        }
    }
}