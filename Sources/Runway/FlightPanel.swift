import AppKit

// MARK: - Feature 6: Multi-Monitor Contextual Overlay Panel

final class FlightPanel: NSPanel {
    private var optionKeyMonitor: Any?

    init(targetScreen: NSScreen) {
        super.init(
            contentRect: targetScreen.frame,
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true

        // Feature 6: Render over full-screen apps at screenSaver level
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle,
            .stationary
        ]

        // Position at exact screen origin
        self.setFrameOrigin(targetScreen.frame.origin)

        // Feature 9: Monitor Option key for click-to-board
        setupOptionKeyMonitor()
    }

    deinit {
        if let monitor = optionKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Feature 9: Option Key Monitoring

    private func setupOptionKeyMonitor() {
        optionKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let optionPressed = event.modifierFlags.contains(.option)
            self?.ignoresMouseEvents = !optionPressed
            return event
        }
    }
}
