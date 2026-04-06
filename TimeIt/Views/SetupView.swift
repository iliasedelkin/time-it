import SwiftUI

struct SetupView: View {
    @Environment(TimerViewModel.self) private var timerViewModel

    @AppStorage("defaultDurationMinutes") private var defaultDurationMinutes = 30

    @State private var durationText = ""
    @State private var taskName = ""
    @State private var showValidationWarning = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case duration
        case taskName
    }

    private var normalizedDefaultDuration: Int {
        max(defaultDurationMinutes, 1)
    }

    private var plannedMinutes: Int {
        if durationText.isEmpty {
            return normalizedDefaultDuration
        }
        return Int(durationText) ?? 0
    }

    private var canStart: Bool {
        plannedMinutes > 0 && !taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 18) {
            TextField(
                "",
                text: $durationText,
                prompt: Text(String(format: L10n.setupDurationPlaceholderFormat, normalizedDefaultDuration))
            )
            .font(.system(size: 48, weight: .thin, design: .monospaced))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .focused($focusedField, equals: .duration)
            .onChange(of: durationText) { _, newValue in
                let filtered = newValue.filter(\.isNumber)
                if filtered != newValue {
                    durationText = filtered
                }
            }
            .onSubmit {
                if durationText.isEmpty {
                    durationText = String(normalizedDefaultDuration)
                }
                focusedField = .taskName
            }

            Text(L10n.setupMinutesLabel)
                .font(.headline)
                .foregroundStyle(.secondary)

            TextField(
                "",
                text: $taskName,
                prompt: Text(L10n.setupTaskNamePlaceholder)
            )
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: .taskName)
            .onSubmit {
                startTapped()
            }

            Button(L10n.startButton) {
                startTapped()
            }
            .adaptiveActionButtonStyle(prominent: true)
            .disabled(!canStart)
            .frame(maxWidth: .infinity)

            if showValidationWarning {
                Text(L10n.setupValidationWarning)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: 360)
        .onAppear {
            focusedField = .duration
        }
    }

    private func startTapped() {
        guard canStart else {
            showValidationWarning = true
            return
        }

        if durationText.isEmpty {
            durationText = String(normalizedDefaultDuration)
        }

        showValidationWarning = false
        _ = timerViewModel.startCountdown(taskName: taskName, plannedMinutes: plannedMinutes)
    }
}
