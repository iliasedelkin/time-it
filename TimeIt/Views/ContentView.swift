import SwiftUI

struct ContentView: View {
    @Environment(TimerViewModel.self) private var timerViewModel

    @AppStorage("appearanceMode") private var appearanceMode = "auto"

    @State private var showingHistory = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            routedView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            SoundPlayer.stopRepeating()
                            showingHistory = true
                        } label: {
                            Image(systemName: "clock")
                        }
                        .help(L10n.historyTitle)
                    }

                    ToolbarItem(placement: .automatic) {
                        Button {
                            SoundPlayer.stopRepeating()
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .help(L10n.settingsTitle)
                    }
                }
                .sheet(isPresented: $showingHistory) {
                    NavigationStack {
                        HistoryView()
                    }
                    .frame(minWidth: 520, minHeight: 420)
                }
                .sheet(isPresented: $showingSettings) {
                    NavigationStack {
                        SettingsView()
                    }
                    .frame(minWidth: 420, minHeight: 420)
                }
        }
        .preferredColorScheme(resolvedColorScheme)
        .simultaneousGesture(TapGesture().onEnded {
            SoundPlayer.stopRepeating()
        })
    }

    @ViewBuilder
    private var routedView: some View {
        switch timerViewModel.state {
        case .idle:
            SetupView()
        case let .running(taskName, plannedMinutes):
            RunningView(taskName: taskName, plannedMinutes: plannedMinutes, isPaused: false)
        case let .paused(taskName, plannedMinutes):
            RunningView(taskName: taskName, plannedMinutes: plannedMinutes, isPaused: true)
        case let .expired(taskName, plannedMinutes):
            ExpiredView(taskName: taskName, plannedMinutes: plannedMinutes)
        case let .stopwatch(taskName, plannedMinutes):
            StopwatchView(taskName: taskName, plannedMinutes: plannedMinutes, isPaused: false)
        case let .stopwatchPaused(taskName, plannedMinutes):
            StopwatchView(taskName: taskName, plannedMinutes: plannedMinutes, isPaused: true)
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
}

#Preview {
    ContentView()
        .environment(TimerViewModel())
}
