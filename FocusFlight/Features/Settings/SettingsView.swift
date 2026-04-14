import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: UserPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FFSpacing.lg) {
                settingsCard(title: "Defaults") {
                    VStack(alignment: .leading, spacing: FFSpacing.md) {
                        Text("Duration")
                            .font(FFTypography.detail)
                            .foregroundStyle(FFColors.textSecondary)

                        Picker("Default duration", selection: $preferences.defaultDurationMinutes) {
                            ForEach(UserPreferences.durationPresets, id: \.self) { preset in
                                Text("\(preset)m").tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("settings.durationPicker")

                        Text("Sound")
                            .font(FFTypography.detail)
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
                        Toggle("Notifications", isOn: $preferences.notificationsEnabled)
                            .tint(FFColors.accent)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("settings.notifications")

                        Toggle("Haptics", isOn: $preferences.hapticsEnabled)
                            .tint(FFColors.accent)
                            .foregroundStyle(FFColors.textPrimary)
                            .accessibilityIdentifier("settings.haptics")
                    }
                }

                settingsCard(title: "About") {
                    Text("\(AppBrand.name) turns a focus block into a quiet flight.")
                        .font(FFTypography.body)
                        .foregroundStyle(FFColors.textSecondary)
                }
            }
            .padding(.horizontal, FFSpacing.md)
            .padding(.vertical, FFSpacing.lg)
        }
        .background(FFColors.background.ignoresSafeArea())
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
        .background(FFColors.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FFColors.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
