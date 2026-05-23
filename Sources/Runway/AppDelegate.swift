import AppKit
import SwiftUI
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var calendarManager: CalendarManager!
    private var timerManager: TimerManager!
    private var onboardingWindow: NSWindow?
    private var dashboardWindow: NSWindow?

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

        if GoogleAuthManager.shared.isSignedIn {
            startEngine()
        } else {
            showOnboarding()
        }

        enableLaunchAtLogin()
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
            window.title = "Runway"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.minSize = NSSize(width: 420, height: 480)
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
