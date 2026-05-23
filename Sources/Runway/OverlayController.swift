import AppKit
import SwiftUI
import IOKit.ps
import CoreAudio

// MARK: - Features 6, 9, 11, 12: Enhanced Overlay Controller

final class OverlayController {
    static let shared = OverlayController()

    private var activePanels: [FlightPanel] = []
    private var interactionPanel: FlightPanel?

    private init() {}

    // MARK: - Feature 12: Check if grounded (Focus/Presentation mode)

    var isGrounded: Bool {
        return isFocusModeActive || isScreenMirroring
    }

    private var isFocusModeActive: Bool {
        // Check DND/Focus via presence of assertion
        // On macOS 12+, we check the DNDNotDisturbing user default
        let dndDefaults = UserDefaults(suiteName: "com.apple.controlcenter")
        if let dnd = dndDefaults?.bool(forKey: "NSStatusItem Visible DoNotDisturb"), dnd {
            return true
        }
        // Also check via distributed notification center flag
        let focusDefaults = UserDefaults(suiteName: "com.apple.Focus")
        if let active = focusDefaults?.bool(forKey: "FocusActive"), active {
            return true
        }
        return false
    }

    private var isScreenMirroring: Bool {
        let screens = NSScreen.screens
        guard screens.count > 1 else { return false }
        // Check if any two screens share the same frame (mirroring)
        for i in 0..<screens.count {
            for j in (i+1)..<screens.count {
                if screens[i].frame == screens[j].frame {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Feature 11: Hardware Validation

    func performPreFlightCheck() -> HardwareStatus {
        var status = HardwareStatus()

        // Check system microphone mute state
        status.isMicMuted = isSystemMicMuted()

        // Check battery level
        let (level, critical) = getBatteryStatus()
        status.batteryLevel = level
        status.isBatteryCritical = critical

        // Check Bluetooth audio
        status.isHeadsetDisconnected = !isBluetoothAudioConnected()

        return status
    }

    private func isSystemMicMuted() -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &size, &deviceID
        )

        guard result == noErr, deviceID != 0 else { return false }

        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        var muted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)

        let muteResult = AudioObjectGetPropertyData(deviceID, &muteAddress, 0, nil, &muteSize, &muted)
        if muteResult == noErr {
            return muted != 0
        }
        return false
    }

    private func getBatteryStatus() -> (Int, Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let first = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: Any],
              let capacity = info[kIOPSCurrentCapacityKey] as? Int
        else {
            return (100, false)
        }
        return (capacity, capacity <= 10)
    }

    private func isBluetoothAudioConnected() -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &size, &deviceID
        )

        guard result == noErr, deviceID != 0 else { return true }

        // Check transport type
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transport: UInt32 = 0
        var transportSize = UInt32(MemoryLayout<UInt32>.size)

        let transportResult = AudioObjectGetPropertyData(deviceID, &transportAddress, 0, nil, &transportSize, &transport)
        guard transportResult == noErr else { return true }

        // kAudioDeviceTransportTypeBluetooth = 'blue'
        let bluetoothTransport: UInt32 = 0x626C7565
        if transport == bluetoothTransport {
            return true // BT is connected and is default
        }

        // If not bluetooth output, we can't confirm headset is connected
        // This is a simplification - in real app we'd scan all devices
        return true
    }

    // MARK: - Show Alert (Feature 6: Multi-Monitor, Feature 7: Three-Stage)

    func showAlert(meeting: MeetingEvent, style: AlertStyle) {
        // Feature 12: Check if grounded
        if isGrounded {
            NotificationCenter.default.post(
                name: .flightGrounded,
                object: nil,
                userInfo: ["meeting": meeting.title]
            )
            return
        }

        // Feature 6: Use active screen (multi-monitor support)
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let screenFrame = screen.frame

        let panel = FlightPanel(targetScreen: screen)

        // Feature 11: Pre-flight hardware check
        let hwStatus = performPreFlightCheck()

        let hostingView: NSView

        switch style {
        case .reminder:
            let view = ReminderAlertView(
                meeting: meeting,
                screenWidth: screenFrame.width,
                screenHeight: screenFrame.height,
                completion: { [weak self, weak panel] in self?.dismissPanel(panel) },
                hardwareWarnings: hwStatus.warnings
            )
            hostingView = NSHostingView(rootView: view)

        case .turbulent:
            let view = TurbulentAlertView(
                meeting: meeting,
                screenWidth: screenFrame.width,
                screenHeight: screenFrame.height,
                completion: { [weak self, weak panel] in self?.dismissPanel(panel) },
                hardwareWarnings: hwStatus.warnings
            )
            hostingView = NSHostingView(rootView: view)

        case .crash:
            let view = CrashLandingAlertView(
                meeting: meeting,
                screenWidth: screenFrame.width,
                screenHeight: screenFrame.height,
                completion: { [weak self, weak panel] in self?.dismissPanel(panel) }
            )
            hostingView = NSHostingView(rootView: view)
        }

        hostingView.frame = screenFrame
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        activePanels.append(panel)
    }

    // MARK: - Feature 10: Autopilot warning

    func showAutopilotWarning(meeting: MeetingEvent) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let panel = FlightPanel(targetScreen: screen)

        let view = AutopilotWarningView(
            meeting: meeting,
            screenWidth: screenFrame.width,
            screenHeight: screenFrame.height,
            completion: { [weak self, weak panel] in self?.dismissPanel(panel) }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = screenFrame
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        activePanels.append(panel)
    }

    // MARK: - Feature 13: Ejection Seat

    func showEjectionSeat() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let panel = FlightPanel(targetScreen: screen)

        let view = EjectionSeatView(
            screenWidth: screenFrame.width,
            screenHeight: screenFrame.height,
            completion: { [weak self, weak panel] in self?.dismissPanel(panel) }
        )

        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = screenFrame
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        activePanels.append(panel)
    }

    // MARK: - Feature 9: Enable interaction temporarily

    func setInteractable(_ enabled: Bool) {
        for panel in activePanels {
            panel.ignoresMouseEvents = !enabled
        }
    }

    private func dismissPanel(_ panel: FlightPanel?) {
        guard let panel = panel else { return }
        panel.orderOut(nil)
        activePanels.removeAll { $0 === panel }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let flightGrounded = Notification.Name("RunwayFlightGrounded")
}
