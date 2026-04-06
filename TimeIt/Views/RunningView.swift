import SwiftUI

struct RunningView: View {
    @Environment(TimerViewModel.self) private var timerViewModel

    let taskName: String
    let plannedMinutes: Int
    let isPaused: Bool

    @State private var showingAddTimeInput = false

    var body: some View {
        VStack(spacing: 20) {
            TimeDisplayView(seconds: timerViewModel.secondsRemaining)

            Text(taskName)
                .font(.headline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)

            if showingAddTimeInput {
                AddTimeInputView(
                    onAdd: { minutes in
                        timerViewModel.addTime(minutes: minutes)
                        withAnimation {
                            showingAddTimeInput = false
                        }
                    },
                    onCancel: {
                        withAnimation {
                            showingAddTimeInput = false
                        }
                    }
                )
                .transition(.opacity)
            } else {
                HStack(spacing: 12) {
                    Button(isPaused ? L10n.resumeButton : L10n.pauseButton) {
                        if isPaused {
                            timerViewModel.resumeCountdown()
                        } else {
                            timerViewModel.pauseCountdown()
                        }
                    }
                    .adaptiveActionButtonStyle()
                    .frame(maxWidth: .infinity)

                    Button(L10n.finishButton) {
                        timerViewModel.finishCurrentTask()
                    }
                    .adaptiveActionButtonStyle(prominent: true)
                    .frame(maxWidth: .infinity)

                    Button(L10n.addTimeButton) {
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
    }
}
