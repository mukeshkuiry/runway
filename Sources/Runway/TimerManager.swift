import Foundation

final class TimerManager {
    private let calendarManager: CalendarManager
    private var trackingTimer: Timer?
    private var refreshTimer: Timer?
    private var triggeredEvents: Set<String> = []

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
    }

    func stopEngineLoop() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func evaluateUpcomingMissions() {
        let now = Date()
        let upcomingMeetings = calendarManager.fetchCachedMeetings()

        for meeting in upcomingMeetings {
            guard !meeting.isAllDay else { continue }

            let timeDelta = meeting.startTime.timeIntervalSince(now)

            // 5-minute reminder (window: 4.5 to 5.5 min)
            if timeDelta > 270 && timeDelta <= 330 {
                let key = "\(meeting.id)-reminder"
                if !triggeredEvents.contains(key) {
                    triggeredEvents.insert(key)
                    fireAlert(meeting: meeting, style: .reminder)
                }
            }

            // Start time alert (window: -30s to +30s)
            if timeDelta > -30 && timeDelta <= 30 {
                let key = "\(meeting.id)-urgent"
                if !triggeredEvents.contains(key) {
                    triggeredEvents.insert(key)
                    fireAlert(meeting: meeting, style: .urgent)
                }
            }
        }

        // Purge old triggers
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
