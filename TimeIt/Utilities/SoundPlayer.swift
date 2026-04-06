import AppKit
import Foundation

@MainActor
final class SoundPlayer {
    private static var repeatingTimer: Timer?

    static func play(named name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }

    static func startRepeating(named name: String, interval: TimeInterval) {
        stopRepeating()
        play(named: name)

        let repeatInterval = max(interval, 1)
        repeatingTimer = Timer.scheduledTimer(withTimeInterval: repeatInterval, repeats: true) { _ in
            Task { @MainActor in
                play(named: name)
            }
        }
        if let repeatingTimer {
            RunLoop.main.add(repeatingTimer, forMode: .common)
        }
    }

    static func stopRepeating() {
        repeatingTimer?.invalidate()
        repeatingTimer = nil
    }

    static let availableSounds: [String] = {
        let url = URL(fileURLWithPath: "/System/Library/Sounds")
        let files = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )) ?? []

        return files
            .filter { $0.pathExtension.lowercased() == "aiff" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }()
}
