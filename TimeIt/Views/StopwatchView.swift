import SwiftUI

struct StopwatchView: View {
    @Environment(TimerViewModel.self) private var timerViewModel

    let taskName: String
    let plannedMinutes: Int
    let isPaused: Bool

    var body: some View {
        VStack(spacing: 20) {
            TimeDisplayView(seconds: timerViewModel.secondsElapsed, prefix: "+")

            Text(taskName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                Button(isPaused ? L10n.resumeButton : L10n.pauseButton) {
                    if isPaused {
                        timerViewModel.resumeStopwatch()
                    } else {
                        timerViewModel.pauseStopwatch()
                    }
                }
                .keyboardShortcut(.space, modifiers: [])
                .adaptiveActionButtonStyle()
                .frame(maxWidth: .infinity)

                Button(L10n.finishButton) {
                    timerViewModel.finishCurrentTask()
                }
                .keyboardShortcut(.return, modifiers: [])
                .adaptiveActionButtonStyle(prominent: true)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
