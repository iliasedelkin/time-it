import SwiftUI

struct SettingsView: View {
    @AppStorage("playSoundOnExpiry") private var playSoundOnExpiry = true
    @AppStorage("selectedSoundName") private var selectedSoundName = "Glass"
    @AppStorage("repeatSoundOnExpiry") private var repeatSoundOnExpiry = false
    @AppStorage("repeatSoundIntervalSeconds") private var repeatSoundIntervalSeconds = 10
    @AppStorage("defaultDurationMinutes") private var defaultDurationMinutes = 30
    @AppStorage("appearanceMode") private var appearanceMode = "auto"

    private let sounds = SoundPlayer.availableSounds

    var body: some View {
        Form {
            Section(L10n.settingsSoundSection) {
                Toggle(L10n.settingsPlaySoundToggle, isOn: $playSoundOnExpiry)

                Picker(L10n.settingsAlertSoundPicker, selection: $selectedSoundName) {
                    ForEach(sounds, id: \.self) { soundName in
                        Text(soundName).tag(soundName)
                    }
                }

                Toggle(L10n.settingsRepeatSoundToggle, isOn: $repeatSoundOnExpiry)
                    .disabled(!playSoundOnExpiry)

                if repeatSoundOnExpiry {
                    Stepper(value: $repeatSoundIntervalSeconds, in: 1...120) {
                        Text(String(format: L10n.settingsRepeatIntervalFormat, repeatSoundIntervalSeconds))
                    }
                    .disabled(!playSoundOnExpiry)
                }

                Button(L10n.previewButton) {
                    SoundPlayer.stopRepeating()
                    SoundPlayer.play(named: selectedSoundName)
                }
                .adaptiveActionButtonStyle()
            }

            Section(L10n.settingsTimerSection) {
                Stepper(value: $defaultDurationMinutes, in: 1...600) {
                    Text(String(format: L10n.settingsDefaultDurationFormat, defaultDurationMinutes))
                }
            }

            Section(L10n.settingsAppearanceSection) {
                Picker(L10n.settingsThemePicker, selection: $appearanceMode) {
                    Text(L10n.settingsThemeAuto).tag("auto")
                    Text(L10n.settingsThemeLight).tag("light")
                    Text(L10n.settingsThemeDark).tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.settingsAboutSection) {
                Text(L10n.settingsAboutName)
                Text(versionLine)
                Text(buildLine)
            }
        }
        .navigationTitle(L10n.settingsTitle)
        .onAppear {
            if !sounds.contains(selectedSoundName) {
                selectedSoundName = sounds.first ?? "Glass"
            }
            defaultDurationMinutes = max(defaultDurationMinutes, 1)
            repeatSoundIntervalSeconds = max(repeatSoundIntervalSeconds, 1)
        }
    }

    private var versionLine: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        return String(format: L10n.settingsVersionFormat, version)
    }

    private var buildLine: String {
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return String(format: L10n.settingsBuildFormat, build)
    }
}
