import SwiftUI

struct TimeDisplayView: View {
    let seconds: Int
    var prefix: String = ""

    var body: some View {
        Text("\(prefix)\(TimerViewModel.formatTime(seconds: seconds))")
            .font(.system(size: 52, weight: .thin, design: .monospaced))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.numericText())
    }
}
