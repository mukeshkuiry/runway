import Foundation
import AppKit

// MARK: - Features 3, 7, 10: Enhanced Timer Manager

final class TimerManager {
    private let calendarManager: CalendarManager
    private var trackingTimer: Timer?
    private var refreshTimer: Timer?
    private var triggeredEvents: Set<String> = []
    private var weatherUpdateTimer: Timer?

    // Feature 10: Autopilot mode
    private var autopilotEnabled: Bool {
        UserDefaults.standard.bool(forKey: "RunwayAutopilotEnabled")
    }

    init(calendarManager: CalendarManager) {
        self.calendarManager = calendarManager
    }

    func startEngineLoop() {
        calendarManager.refreshCache()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.evaluateUpcomingMissions()
        }

        // Check every 10 seconds
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.evaluateUpcomingMissions()
        }

        // Refresh calendar data every 60 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.calendarManager.refreshCache()
        }

        // Feature 3: Weather update every 5 minutes
        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            self?.updateWeather()
        }

        // Initial weather computation
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.updateWeather()
        }
    }

    func stopEngineLoop() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        weatherUpdateTimer?.invalidate()
        weatherUpdateTimer = nil
    }

    // MARK: - Feature 3: Weather Update

    private func updateWeather() {
        let weather = calendarManager.computeWeather()
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .weatherUpdated,
                object: nil,
                userInfo: ["weather": weather]
            )
        }
    }

    // MARK: - Feature 7: Three-Stage Evaluation

    private func evaluateUpcomingMissions() {
        let now = Date()
        let upcomingMeetings = calendarManager.fetchCachedMeetings()

        for meeting in upcomingMeetings {
            guard !meeting.isAllDay || meeting.aircraftType == .blimp else {
                // Blimp for all-day - show once
                let blimpKey = "\(meeting.id)-blimp"
                if !triggeredEvents.contains(blimpKey) && meeting.aircraftType == .blimp {
                    triggeredEvents.insert(blimpKey)
                    fireAlert(meeting: meeting, style: .reminder)
                }
                continue
            }

            let timeDelta = meeting.startTime.timeIntervalSince(now)

            // T-5 minutes: Standard flight (window: 4.5 to 5.5 min = 270-330s)
            if timeDelta > 270 && timeDelta <= 330 {
                let key = "\(meeting.id)-t5"
                if !triggeredEvents.contains(key) {
                    triggeredEvents.insert(key)
                    fireAlert(meeting: meeting, style: .reminder)
                }
            }

            // T-2 minutes: Turbulent flight (window: 1.5 to 2.5 min = 90-150s)
            if timeDelta > 90 && timeDelta <= 150 {
                let key = "\(meeting.id)-t2"
                if !triggeredEvents.contains(key) {
                    triggeredEvents.insert(key)
                    fireAlert(meeting: meeting, style: .turbulent)
                }
            }

            // T-0 minutes: Crash landing (window: -30s to +30s)
            if timeDelta > -30 && timeDelta <= 30 {
                let key = "\(meeting.id)-t0"
                if !triggeredEvents.contains(key) {
                    triggeredEvents.insert(key)

                    // Feature 10: Autopilot mode
                    if autopilotEnabled, let url = meeting.conferenceURL {
                        // Show autopilot warning 15s before launch
                        OverlayController.shared.showAutopilotWarning(meeting: meeting)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        fireAlert(meeting: meeting, style: .crash)
                    }
                }
            }
        }

        // Purge old triggers (older than 15 minutes)
        let cutoff = now.addingTimeInterval(-900)
        triggeredEvents = triggeredEvents.filter { key in
            upcomingMeetings.contains { meeting in
                key.hasPrefix(meeting.id) && meeting.startTime > cutoff
            }
        }
    }

    private func fireAlert(meeting: MeetingEvent, style: AlertStyle) {
        DispatchQueue.main.async {
            OverlayController.shared.showAlert(meeting: meeting, style: style)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let weatherUpdated = Notification.Name("RunwayWeatherUpdated")
}
