import SwiftUI

struct AddTimeInputView: View {
    let onAdd: (Int) -> Void
    let onCancel: () -> Void

    @State private var minutesText = ""
    @State private var showValidationWarning = false

    @FocusState private var focused: Bool

    private var minutesValue: Int {
        Int(minutesText) ?? 0
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField(
                "",
                text: $minutesText,
                prompt: Text(L10n.addTimePlaceholder)
            )
            .textFieldStyle(.roundedBorder)
            .focused($focused)
            .onChange(of: minutesText) { _, newValue in
                let filtered = newValue.filter(\.isNumber)
                if filtered != newValue {
                    minutesText = filtered
                }
            }
            .onSubmit {
                confirm()
            }

            Button(L10n.addButton) {
                confirm()
            }
            .adaptiveActionButtonStyle(prominent: true)

            Button(L10n.cancelButton) {
                onCancel()
            }
            .adaptiveActionButtonStyle()
        }
        .overlay(alignment: .bottomLeading) {
            if showValidationWarning {
                Text(L10n.addTimeValidationWarning)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .offset(y: 20)
            }
        }
        .onAppear {
            focused = true
        }
        .onExitCommand {
            onCancel()
        }
    }

    private func confirm() {
        guard minutesValue > 0 else {
            showValidationWarning = true
            return
        }

        showValidationWarning = false
        onAdd(minutesValue)
    }
}
