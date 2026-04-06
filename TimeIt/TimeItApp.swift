import SwiftUI
import SwiftData

@MainActor
@main
struct TimeItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let sharedModelContainer: ModelContainer
    private let timerViewModel: TimerViewModel

    init() {
        sharedModelContainer = Self.makeModelContainer()
        timerViewModel = TimerViewModel()
        appDelegate.configure(modelContainer: sharedModelContainer, timerViewModel: timerViewModel)
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            TaskRecord.self,
        ])

        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
