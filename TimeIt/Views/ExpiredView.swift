import SwiftUI

struct ExpiredView: View {
    @Environment(TimerViewModel.self) private var timerViewModel

    @AppStorage("playSoundOnExpiry") private var playSoundOnExpiry = true
    @AppStorage("selectedSoundName") private var selectedSoundName = "Glass"
    @AppStorage("repeatSoundOnExpiry") private var repeatSoundOnExpiry = false
    @AppStorage("repeatSoundIntervalSeconds") private var repeatSoundIntervalSeconds = 10

    let taskName: String
    let plannedMinutes: Int

    @State private var showingAddTimeInput = false

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.expiredTitle)
                .font(.title2.weight(.semibold))

            Text(taskName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            if showingAddTimeInput {
                AddTimeInputView(
                    onAdd: { minutes in
                        SoundPlayer.stopRepeating()
                        timerViewModel.addTime(minutes: minutes)
                        withAnimation {
                            showingAddTimeInput = false
                        }
                    },
                    onCancel: {
                        SoundPlayer.stopRepeating()
                        withAnimation {
                            showingAddTimeInput = false
                        }
                    }
                )
                .transition(.opacity)
            } else {
                HStack(spacing: 12) {
                    Button(L10n.takeTimeButton) {
                        SoundPlayer.stopRepeating()
                        timerViewModel.startStopwatchFromExpired()
                    }
                    .adaptiveActionButtonStyle()
                    .frame(maxWidth: .infinity)

                    Button(L10n.finishButton) {
                        SoundPlayer.stopRepeating()
                        timerViewModel.finishCurrentTask()
                    }
                    .adaptiveActionButtonStyle(prominent: true)
                    .frame(maxWidth: .infinity)

                    Button(L10n.addTimeButton) {
                        SoundPlayer.stopRepeating()
                        withAnimation {
                            showingAddTimeInput = true
                        }
                    }
                    .adaptiveActionButtonStyle()
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingAddTimeInput)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onAppear {
            guard playSoundOnExpiry else {
                return
            }
            if repeatSoundOnExpiry {
                SoundPlayer.startRepeating(
                    named: selectedSoundName,
                    interval: TimeInterval(max(repeatSoundIntervalSeconds, 1))
                )
            } else {
                SoundPlayer.play(named: selectedSoundName)
            }
        }
        .onDisappear {
            SoundPlayer.stopRepeating()
        }
    }
}
