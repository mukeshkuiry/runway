import Foundation

enum AlertStyle {
    case reminder    // 5 minutes before
    case urgent      // Meeting starting now
}

struct MeetingEvent: Identifiable {
    let id: String
    let title: String
    let startTime: Date
    let endTime: Date
    let conferenceURL: URL?
    let location: String?
    let attendees: [Attendee]
    let calendarColor: String?
    let description: String?
    let isAllDay: Bool

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationFormatted: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    var isHappening: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }

    var isPast: Bool {
        return Date() > endTime
    }

    var minutesUntilStart: Int {
        return Int(startTime.timeIntervalSince(Date()) / 60)
    }
}

struct Attendee {
    let name: String
    let email: String
    let status: AttendeeStatus
}

enum AttendeeStatus {
    case accepted
    case declined
    case tentative
    case needsAction
}
