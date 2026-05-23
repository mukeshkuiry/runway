import Foundation

// MARK: - Alert Styles

enum AlertStyle {
    case reminder    // T-5 minutes: calm horizontal flight
    case turbulent   // T-2 minutes: shaking turbulent flight
    case crash       // T-0 minutes: nose-dive crash landing
}

// MARK: - Aircraft Types (Feature 8)

enum AircraftType: String {
    case biplane       // casual 1:1s, coffee chats
    case passengerJet  // default corporate meetings
    case rocket        // urgent, client, demo, incident
    case blimp         // all-day events

    var transitDuration: Double {
        switch self {
        case .biplane: return 8.0
        case .passengerJet: return 5.0
        case .rocket: return 2.5
        case .blimp: return 20.0
        }
    }

    var displayName: String {
        switch self {
        case .biplane: return "Biplane"
        case .passengerJet: return "Passenger Jet"
        case .rocket: return "Supersonic Rocket"
        case .blimp: return "Blimp"
        }
    }

    static func classify(title: String, isAllDay: Bool) -> AircraftType {
        if isAllDay { return .blimp }
        let lower = title.lowercased()
        let rocketKeywords = ["urgent", "client", "demo", "incident", "escalation", "outage", "p0", "p1", "emergency"]
        let biplaneKeywords = ["1:1", "1-1", "one on one", "coffee", "casual", "catch up", "catchup", "chat", "social"]

        if rocketKeywords.contains(where: { lower.contains($0) }) { return .rocket }
        if biplaneKeywords.contains(where: { lower.contains($0) }) { return .biplane }
        return .passengerJet
    }
}

// MARK: - Conference Platform (Feature 2)

enum ConferencePlatform: String {
    case zoom = "zoom"
    case googleMeet = "google_meet"
    case teams = "teams"
    case unknown = "unknown"

    var iconName: String {
        switch self {
        case .zoom: return "video.fill"
        case .googleMeet: return "person.wave.2.fill"
        case .teams: return "bubble.left.and.bubble.right.fill"
        case .unknown: return "video.fill"
        }
    }

    var displayName: String {
        switch self {
        case .zoom: return "Zoom"
        case .googleMeet: return "Google Meet"
        case .teams: return "Teams"
        case .unknown: return "Video"
        }
    }
}

// MARK: - Meeting Urgency (Feature 1)

enum MeetingUrgency {
    case scheduled      // >5 min away (green)
    case boardingNow    // <=5 min away (pulsing yellow)
    case inProgress     // meeting is currently happening (blue)
    case past           // already ended

    var colorName: String {
        switch self {
        case .scheduled: return "green"
        case .boardingNow: return "yellow"
        case .inProgress: return "blue"
        case .past: return "gray"
        }
    }
}

// MARK: - Calendar Weather (Feature 3)

enum CalendarWeather: String {
    case clearSkies = "clear"
    case overcast = "overcast"
    case stormWarning = "storm"

    var icon: String {
        switch self {
        case .clearSkies: return "sun.max.fill"
        case .overcast: return "cloud.fill"
        case .stormWarning: return "cloud.bolt.rain.fill"
        }
    }

    var menuBarIcon: String {
        switch self {
        case .clearSkies: return "airplane.departure"
        case .overcast: return "cloud.fill"
        case .stormWarning: return "cloud.bolt.fill"
        }
    }

    var description: String {
        switch self {
        case .clearSkies: return "Clear Skies - Light meeting day"
        case .overcast: return "Overcast - Moderate schedule"
        case .stormWarning: return "Storm Warning - Back-to-back meetings"
        }
    }
}

// MARK: - Habit Analytics (Feature 5)

struct DailyMetrics: Codable {
    let date: String // yyyy-MM-dd
    var totalMeetingMinutes: Int
    var deepWorkMinutes: Int
    var backToBackBlocks: Int
    var earlyExits: Int
    var meetingCount: Int

    var airTimeHours: Double { Double(totalMeetingMinutes) / 60.0 }
    var turbulenceScore: Int { backToBackBlocks }
    var emergencyLandings: Int { earlyExits }
}

struct WeeklyReport: Codable {
    let weekStartDate: String
    var dailyMetrics: [DailyMetrics]

    var totalAirTime: Double {
        dailyMetrics.reduce(0) { $0 + $1.airTimeHours }
    }
    var avgTurbulence: Double {
        guard !dailyMetrics.isEmpty else { return 0 }
        return Double(dailyMetrics.reduce(0) { $0 + $1.turbulenceScore }) / Double(dailyMetrics.count)
    }
    var totalEmergencyLandings: Int {
        dailyMetrics.reduce(0) { $0 + $1.emergencyLandings }
    }
}

// MARK: - Hardware Check (Feature 11)

struct HardwareStatus {
    var isMicMuted: Bool = false
    var isHeadsetDisconnected: Bool = false
    var isBatteryCritical: Bool = false
    var batteryLevel: Int = 100

    var warnings: [String] {
        var w: [String] = []
        if isMicMuted { w.append("Mic Muted System-Wide") }
        if isHeadsetDisconnected { w.append("Bluetooth Headset Disconnected") }
        if isBatteryCritical { w.append("Battery Critical (\(batteryLevel)%)") }
        return w
    }

    var hasIssues: Bool { !warnings.isEmpty }
}

// MARK: - Meeting Event

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
    var platform: ConferencePlatform

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

    var secondsUntilStart: TimeInterval {
        return startTime.timeIntervalSince(Date())
    }

    var urgency: MeetingUrgency {
        if isPast { return .past }
        if isHappening { return .inProgress }
        if minutesUntilStart <= 5 { return .boardingNow }
        return .scheduled
    }

    var aircraftType: AircraftType {
        AircraftType.classify(title: title, isAllDay: isAllDay)
    }

    // Feature 4: Conflict detection
    func overlaps(with other: MeetingEvent) -> Bool {
        guard !isAllDay && !other.isAllDay else { return false }
        return startTime < other.endTime && endTime > other.startTime
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
