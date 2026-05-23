import AppKit

final class FlightPanel: NSPanel {
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

        // Render over apps, presentations, and full-screen spaces
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        // Position at exact screen origin
        self.setFrameOrigin(targetScreen.frame.origin)
    }
}
