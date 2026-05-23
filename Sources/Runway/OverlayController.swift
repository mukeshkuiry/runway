import AppKit
import SwiftUI

final class OverlayController {
    static let shared = OverlayController()

    private var activePanels: [FlightPanel] = []

    private init() {}

    func showAlert(meeting: MeetingEvent, style: AlertStyle) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame

        let panel = FlightPanel(targetScreen: screen)

        let hostingView: NSView

        switch style {
        case .reminder:
            let view = ReminderAlertView(
                meeting: meeting,
                screenWidth: screenFrame.width,
                screenHeight: screenFrame.height
            ) { [weak self, weak panel] in
                self?.dismissPanel(panel)
            }
            hostingView = NSHostingView(rootView: view)

        case .urgent:
            let view = UrgentAlertView(
                meeting: meeting,
                screenWidth: screenFrame.width,
                screenHeight: screenFrame.height
            ) { [weak self, weak panel] in
                self?.dismissPanel(panel)
            }
            hostingView = NSHostingView(rootView: view)
        }

        hostingView.frame = screenFrame
        panel.contentView = hostingView
        panel.orderFrontRegardless()
        activePanels.append(panel)
    }

    private func dismissPanel(_ panel: FlightPanel?) {
        guard let panel = panel else { return }
        panel.orderOut(nil)
        activePanels.removeAll { $0 === panel }
    }
}
