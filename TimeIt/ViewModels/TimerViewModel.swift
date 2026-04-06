import Foundation
import Observation
import SwiftData

extension Notification.Name {
    static let menuBarLabelDidChange = Notification.Name("TimerViewModel.menuBarLabelDidChange")
}

@MainActor
@Observable
final class TimerViewModel {
    enum TimerState: Equatable {
        case idle
        case running(taskName: String, plannedMinutes: Int)
        case paused(taskName: String, plannedMinutes: Int)
        case expired(taskName: String, plannedMinutes: Int)
        case stopwatch(taskName: String, plannedMinutes: Int)
        case stopwatchPaused(taskName: String, plannedMinutes: Int)
    }

    nonisolated static let menuBarLabelNotificationKey = "label"

    var state: TimerState = .idle {
        didSet {
            refreshMenuBarLabel()
        }
    }
    var secondsRemaining: Int = 0 {
        didSet {
            refreshMenuBarLabel()
        }
    }
    var secondsElapsed: Int = 0 {
        didSet {
            refreshMenuBarLabel()
        }
    }
    var taskStartedAt: Date?
    var menuBarLabel: String = "" {
        didSet {
            guard oldValue != menuBarLabel else {
                return
            }
            NotificationCenter.default.post(
                name: .menuBarLabelDidChange,
                object: self,
                userInfo: [Self.menuBarLabelNotificationKey: menuBarLabel]
            )
        }
    }

    private var timer: Timer?
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @discardableResult
    func startCountdown(taskName: String, plannedMinutes: Int) -> Bool {
        let trimmedName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard plannedMinutes > 0, !trimmedName.isEmpty else {
            return false
        }

        timer?.invalidate()
        secondsElapsed = 0
        secondsRemaining = plannedMinutes * 60
        taskStartedAt = Date()
        state = .running(taskName: trimmedName, plannedMinutes: plannedMinutes)
        scheduleTickingTimer()
        return true
    }

    func pauseCountdown() {
        guard case let .running(taskName, plannedMinutes) = state else {
            return
        }

        timer?.invalidate()
        state = .paused(taskName: taskName, plannedMinutes: plannedMinutes)
    }

    func resumeCountdown() {
        guard case let .paused(taskName, plannedMinutes) = state else {
            return
        }

        state = .running(taskName: taskName, plannedMinutes: plannedMinutes)
        scheduleTickingTimer()
    }

    func pauseStopwatch() {
        guard case let .stopwatch(taskName, plannedMinutes) = state else {
            return
        }

        timer?.invalidate()
        state = .stopwatchPaused(taskName: taskName, plannedMinutes: plannedMinutes)
    }

    func resumeStopwatch() {
        guard case let .stopwatchPaused(taskName, plannedMinutes) = state else {
            return
        }

        state = .stopwatch(taskName: taskName, plannedMinutes: plannedMinutes)
        scheduleTickingTimer()
    }

    func startStopwatchFromExpired() {
        guard case let .expired(taskName, plannedMinutes) = state else {
            return
        }

        secondsElapsed = 0
        state = .stopwatch(taskName: taskName, plannedMinutes: plannedMinutes)
        scheduleTickingTimer()
    }

    func addTime(minutes: Int) {
        guard minutes > 0 else {
            return
        }

        let addedSeconds = minutes * 60

        switch state {
        case .running:
            secondsRemaining += addedSeconds
        case .paused:
            secondsRemaining += addedSeconds
        case let .expired(taskName, plannedMinutes):
            secondsRemaining += addedSeconds
            state = .running(taskName: taskName, plannedMinutes: plannedMinutes)
            scheduleTickingTimer()
        case .idle, .stopwatch, .stopwatchPaused:
            break
        }
    }

    func finishCurrentTask() {
        saveCurrentTask(finishedAt: Date())
        resetToIdle()
    }

    func saveCurrentTask(finishedAt: Date) {
        guard let modelContext, let startedAt = taskStartedAt else {
            return
        }

        guard let session = currentSessionDetails else {
            return
        }

        let record = TaskRecord(
            name: session.taskName,
            plannedMinutes: session.plannedMinutes,
            startedAt: startedAt,
            finishedAt: finishedAt,
            wasStopwatch: session.wasStopwatch
        )

        modelContext.insert(record)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save task: \(error)")
        }
    }

    static func formatTime(seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)

        if clampedSeconds >= 3600 {
            let hours = clampedSeconds / 3600
            let minutes = (clampedSeconds % 3600) / 60
            let remainingSeconds = clampedSeconds % 60
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        let minutes = clampedSeconds / 60
        let remainingSeconds = clampedSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private var currentSessionDetails: (taskName: String, plannedMinutes: Int, wasStopwatch: Bool)? {
        switch state {
        case let .running(taskName, plannedMinutes),
             let .paused(taskName, plannedMinutes),
             let .expired(taskName, plannedMinutes):
            return (taskName, plannedMinutes, false)
        case let .stopwatch(taskName, plannedMinutes),
             let .stopwatchPaused(taskName, plannedMinutes):
            return (taskName, plannedMinutes, true)
        case .idle:
            return nil
        }
    }

    private func resetToIdle() {
        timer?.invalidate()
        timer = nil
        taskStartedAt = nil
        secondsRemaining = 0
        secondsElapsed = 0
        state = .idle
        menuBarLabel = ""
    }

    private func scheduleTickingTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleTick()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func handleTick() {
        switch state {
        case let .running(taskName, plannedMinutes):
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            }
            if secondsRemaining <= 0 {
                secondsRemaining = 0
                timer?.invalidate()
                timer = nil
                state = .expired(taskName: taskName, plannedMinutes: plannedMinutes)
            }
        case .stopwatch:
            secondsElapsed += 1
        case .idle, .paused, .expired, .stopwatchPaused:
            break
        }
    }

    private func refreshMenuBarLabel() {
        switch state {
        case .idle:
            menuBarLabel = ""
        case .running:
            menuBarLabel = Self.formatTime(seconds: secondsRemaining)
        case .paused:
            menuBarLabel = "\(Self.formatTime(seconds: secondsRemaining)) \(L10n.pauseIndicator)"
        case .expired:
            menuBarLabel = Self.formatTime(seconds: 0)
        case .stopwatch:
            menuBarLabel = "+\(Self.formatTime(seconds: secondsElapsed))"
        case .stopwatchPaused:
            menuBarLabel = "+\(Self.formatTime(seconds: secondsElapsed)) \(L10n.pauseIndicator)"
        }
    }
}
