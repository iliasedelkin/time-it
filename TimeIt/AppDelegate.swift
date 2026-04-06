import AppKit
import SwiftUI
import SwiftData

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var menuBarObserver: NSObjectProtocol?

    private var modelContainer: ModelContainer?
    private var timerViewModel: TimerViewModel?
    private var didFinishLaunching = false
    private var didSetupInterface = false

    func configure(modelContainer: ModelContainer, timerViewModel: TimerViewModel) {
        self.modelContainer = modelContainer
        self.timerViewModel = timerViewModel
        timerViewModel.configure(modelContext: modelContainer.mainContext)
        setupInterfaceIfNeeded()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        didFinishLaunching = true
        setupInterfaceIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard let timerViewModel else {
            return
        }

        switch timerViewModel.state {
        case .running, .paused, .stopwatch, .stopwatchPaused:
            timerViewModel.saveCurrentTask(finishedAt: Date())
        case .idle, .expired:
            break
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func setupInterfaceIfNeeded() {
        guard !didSetupInterface, didFinishLaunching, let modelContainer, let timerViewModel else {
            return
        }

        didSetupInterface = true

        setupStatusItem()
        setupPanel(modelContainer: modelContainer, timerViewModel: timerViewModel)
        observeMenuBarLabelChanges(timerViewModel: timerViewModel)
        updateStatusButtonTitle(with: timerViewModel.menuBarLabel)
    }

    private func setupStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)
        statusItem.button?.sendAction(on: [.leftMouseUp])
        self.statusItem = statusItem
    }

    private func setupPanel(modelContainer: ModelContainer, timerViewModel: TimerViewModel) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = L10n.appName
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.minSize = NSSize(width: 280, height: 340)
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let rootView = ContentView()
            .environment(timerViewModel)
            .modelContainer(modelContainer)

        panel.contentView = NSHostingView(rootView: rootView)
        panel.center()

        self.panel = panel
    }

    private func observeMenuBarLabelChanges(timerViewModel: TimerViewModel) {
        menuBarObserver = NotificationCenter.default.addObserver(
            forName: .menuBarLabelDidChange,
            object: timerViewModel,
            queue: .main
        ) { [weak self] notification in
            let label = notification.userInfo?[TimerViewModel.menuBarLabelNotificationKey] as? String ?? ""
            Task { @MainActor [weak self] in
                self?.updateStatusButtonTitle(with: label)
            }
        }
    }

    private func updateStatusButtonTitle(with label: String) {
        guard let button = statusItem?.button else {
            return
        }

        if label.isEmpty {
            button.title = ""
            let image = NSImage(systemSymbolName: "timer", accessibilityDescription: L10n.appName)
            image?.isTemplate = true
            button.image = image
        } else {
            button.image = nil
            button.title = label
        }
    }

    @objc
    private func togglePanel() {
        guard let panel else {
            return
        }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
