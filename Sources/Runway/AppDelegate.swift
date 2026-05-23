import AppKit
import SwiftUI
import ServiceManagement
import Carbon.HIToolbox

// MARK: - Full Featured AppDelegate (Features 3, 4, 10, 12, 13)

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var calendarManager: CalendarManager!
    private var timerManager: TimerManager!
    private var onboardingWindow: NSWindow?
    private var dashboardWindow: NSWindow?
    private var ejectionHotKeyRef: EventHotKeyRef?
    private var groundedObserver: Any?
    private var weatherObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "airplane.departure", accessibilityDescription: "Runway")
            button.image?.size = NSSize(width: 18, height: 18)
            button.action = #selector(statusBarClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        calendarManager = CalendarManager()
        timerManager = TimerManager(calendarManager: calendarManager)

        // Feature 12: Observe grounded notifications
        groundedObserver = NotificationCenter.default.addObserver(
            forName: .flightGrounded, object: nil, queue: .main
        ) { [weak self] notification in
            self?.handleGroundedFlight(notification)
        }

        // Feature 3: Observe weather updates for menu bar icon
        weatherObserver = NotificationCenter.default.addObserver(
            forName: .weatherUpdated, object: nil, queue: .main
        ) { [weak self] notification in
            if let weather = notification.userInfo?["weather"] as? CalendarWeather {
                self?.updateMenuBarIcon(weather: weather)
            }
        }

        // Feature 13: Register global hotkey (Cmd+Opt+Ctrl+E)
        registerEjectionHotkey()

        if GoogleAuthManager.shared.isSignedIn {
            startEngine()
        } else {
            showOnboarding()
        }

        enableLaunchAtLogin()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = groundedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = weatherObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        unregisterEjectionHotkey()
    }

    // MARK: - Feature 3: Menu Bar Weather Icon

    private func updateMenuBarIcon(weather: CalendarWeather) {
        guard let button = statusItem.button else { return }
        let iconName = weather.menuBarIcon
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Runway - \(weather.description)")
        button.image?.size = NSSize(width: 18, height: 18)
    }

    // MARK: - Feature 12: Grounded Flight Handler

    private func handleGroundedFlight(_ notification: Notification) {
        // Show amber badge on menu bar
        if let button = statusItem.button {
            button.appearsDisabled = false
            // Flash the icon briefly
            let originalImage = button.image
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Flight Grounded")
            button.image?.size = NSSize(width: 18, height: 18)
            button.contentTintColor = .orange

            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                button.image = originalImage
                button.contentTintColor = nil
            }
        }
    }

    // MARK: - Feature 13: Ejection Seat Hotkey (Cmd+Opt+Ctrl+E)

    private func registerEjectionHotkey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x52574559) // "RWEY"
        hotKeyID.id = 1

        // Cmd + Opt + Ctrl + E
        let modifiers: UInt32 = UInt32(cmdKey | optionKey | controlKey)
        let keyCode: UInt32 = 14 // 'E' key

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status == noErr {
            ejectionHotKeyRef = hotKeyRef
        }

        // Install event handler
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            DispatchQueue.main.async {
                AppDelegate.handleEjectionSeat()
            }
            return noErr
        }, 1, &eventSpec, nil, nil)
    }

    private func unregisterEjectionHotkey() {
        if let ref = ejectionHotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    private static func handleEjectionSeat() {
        // Show ejection seat animation
        OverlayController.shared.showEjectionSeat()

        // Background automation: minimize browser, set slack away
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Minimize frontmost app window
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                let script = """
                tell application "System Events"
                    tell process "\(frontApp.localizedName ?? "")"
                        try
                            click button 3 of window 1
                        end try
                    end tell
                end tell
                """
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            }

            // Toggle Slack status to Away via AppleScript
            let slackScript = """
            tell application "System Events"
                if exists (process "Slack") then
                    tell application "Slack" to activate
                    delay 0.3
                    keystroke "/" using command down
                    delay 0.2
                    keystroke "away"
                    delay 0.1
                    key code 36
                end if
            end tell
            """
            if let script = NSAppleScript(source: slackScript) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
            }

            // Show fake system notification as visual excuse
            let notification = NSUserNotification()
            notification.title = "System Update Required"
            notification.informativeText = "macOS needs to restart to apply critical security updates."
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    // MARK: - Status Bar

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggleDashboard()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        if GoogleAuthManager.shared.isSignedIn {
            let syncItem = NSMenuItem(title: "Sync Now", action: #selector(syncNow), keyEquivalent: "r")
            syncItem.target = self
            menu.addItem(syncItem)

            menu.addItem(NSMenuItem.separator())

            // Feature 10: Autopilot toggle
            let autopilotItem = NSMenuItem(title: "Autopilot Mode", action: #selector(toggleAutopilot), keyEquivalent: "")
            autopilotItem.target = self
            autopilotItem.state = UserDefaults.standard.bool(forKey: "RunwayAutopilotEnabled") ? .on : .off
            menu.addItem(autopilotItem)

            // Feature 3: Weather status
            let weatherItem = NSMenuItem(title: calendarManager.calendarWeather.description, action: nil, keyEquivalent: "")
            weatherItem.isEnabled = false
            menu.addItem(weatherItem)

            // Feature 4: Conflicts
            if !calendarManager.conflicts.isEmpty {
                let conflictItem = NSMenuItem(
                    title: "ATC Alert: \(calendarManager.conflicts.count) conflict(s)",
                    action: nil, keyEquivalent: ""
                )
                conflictItem.isEnabled = false
                menu.addItem(conflictItem)
            }

            menu.addItem(NSMenuItem.separator())

            let disconnectItem = NSMenuItem(title: "Disconnect Google Calendar", action: #selector(disconnectGoogle), keyEquivalent: "")
            disconnectItem.target = self
            menu.addItem(disconnectItem)
        } else {
            let connectItem = NSMenuItem(title: "Connect Google Calendar...", action: #selector(showConnect), keyEquivalent: "")
            connectItem.target = self
            menu.addItem(connectItem)
        }

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Runway", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    // MARK: - Dashboard

    private func toggleDashboard() {
        if let window = dashboardWindow, window.isVisible {
            window.close()
            return
        }
        showDashboard()
    }

    private func showDashboard() {
        guard GoogleAuthManager.shared.isSignedIn else {
            showOnboarding()
            return
        }

        if dashboardWindow == nil {
            let dashboard = MeetingsDashboardView(calendarManager: calendarManager)
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 640),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = NSHostingView(rootView: dashboard)
            window.title = "Runway - Departure Board"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 420, height: 480)
            window.backgroundColor = NSColor(red: 0.06, green: 0.07, blue: 0.1, alpha: 1.0)
            dashboardWindow = window
        }

        if let button = statusItem.button, let buttonWindow = button.window {
            let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let x = buttonFrame.midX - 260
            let y = buttonFrame.minY - 650
            dashboardWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            dashboardWindow?.center()
        }

        dashboardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        let onboardingView = OnboardingView { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.startEngine()
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: onboardingView)
        window.title = "Welcome to Runway"
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    // MARK: - Engine

    private func startEngine() {
        calendarManager.refreshCache()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.timerManager.startEngineLoop()
        }
    }

    // MARK: - Actions

    @objc private func syncNow() {
        calendarManager.refreshCache()
    }

    @objc private func showConnect() {
        showOnboarding()
    }

    @objc private func disconnectGoogle() {
        timerManager.stopEngineLoop()
        GoogleAuthManager.shared.signOut()
        showOnboarding()
    }

    @objc private func toggleAutopilot() {
        let current = UserDefaults.standard.bool(forKey: "RunwayAutopilotEnabled")
        UserDefaults.standard.set(!current, forKey: "RunwayAutopilotEnabled")
    }

    @objc private func quitApp() {
        timerManager.stopEngineLoop()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Launch at Login

    @objc private func toggleLaunchAtLogin() {
        if isLaunchAtLoginEnabled() {
            disableLaunchAtLogin()
        } else {
            enableLaunchAtLogin()
        }
    }

    private func enableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        }
    }

    private func disableLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.unregister()
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
}
