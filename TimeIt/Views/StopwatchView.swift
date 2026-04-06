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
                .adaptiveActionButtonStyle()
                .frame(maxWidth: .infinity)

                Button(L10n.finishButton) {
                    timerViewModel.finishCurrentTask()
                }
                .adaptiveActionButtonStyle(prominent: true)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
