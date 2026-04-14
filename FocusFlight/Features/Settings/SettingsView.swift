import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                summaryCard

                settingsCard(title: "Defaults") {
                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        Text("Length")
                            .font(FFTypography.eyebrow)
                            .foregroundStyle(FFColors.textSecondary)

                        Picker("Default duration", selection: $preferences.defaultDurationMinutes) {
                            ForEach(UserPreferences.durationPresets, id: \.self) { preset in
                                Text("\(preset)m").tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("settings.durationPicker")

                        Text("Sound")
                            .font(FFTypography.eyebrow)
                            .foregroundStyle(FFColors.textSecondary)

                        Picker("Sound", selection: $preferences.defaultAudioTrackID) {
                            ForEach(UserPreferences.AudioTrack.allCases) { track in
                                Text(track.title).tag(track.id)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("settings.soundPicker")

                        HStack {
                            Text("Level")
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                            Spacer()
                            Text("\(Int(preferences.audioVolume * 100))%")
                                .font(FFTypography.detail)
                                .foregroundStyle(FFColors.textSecondary)
                        }

                        Slider(value: $preferences.audioVolume, in: 0...1)
                            .tint(FFColors.accent)
                            .accessibilityIdentifier("settings.volume")
                    }
                }

                settingsCard(title: "Options") {
                    VStack(spacing: FFSpacing.md) {
                        Toggle("Session Reminder", isOn: $preferences.notificationsEnabled)
                            .tint(FFColors.accent)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("settings.notifications")

                        Toggle("Vibration", isOn: $preferences.hapticsEnabled)
                            .tint(FFColors.accent)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("settings.haptics")
                    }
                }

                settingsCard(title: "About") {
                    Text("Aureline keeps one quiet route ready whenever you want to focus.")
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFScreenBackground())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FFSpacing.md) {
            Text(title)
                .font(FFTypography.sectionTitle)
                .foregroundStyle(FFColors.textPrimary)
            content()
        }
        .padding(FFSpacing.lg)
        .ffCardSurface()
    }

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: FFSpacing.md) {
            Image("LaunchBrand")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(12)
                .background(FFColors.panelRaised.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(AppBrand.name)
                    .font(FFTypography.sectionTitle)
                    .foregroundStyle(FFColors.textPrimary)

                Text("Set the flight length, sound, and reminders you want ready by default.")
                    .font(FFTypography.detail)
                    .foregroundStyle(FFColors.textSecondary)
            }
        }
        .padding(FFSpacing.lg)
        .ffCardSurface(elevated: true)
    }
}
