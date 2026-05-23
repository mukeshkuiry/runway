import Foundation

/// Fetches upcoming events from Google Calendar API with smart URL extraction
final class CalendarManager: ObservableObject {
    @Published var meetings: [MeetingEvent] = []
    @Published var calendarWeather: CalendarWeather = .clearSkies
    @Published var conflicts: [(MeetingEvent, MeetingEvent)] = []

    private var cachedMeetings: [MeetingEvent] = []

    // MARK: - Feature 2: Smart URL Extraction Patterns

    private static let zoomPattern = try! NSRegularExpression(
        pattern: #"https?://[\w.-]*zoom\.us/[jw]/[\w?=&/%-]+"#,
        options: .caseInsensitive
    )
    private static let meetPattern = try! NSRegularExpression(
        pattern: #"https?://meet\.google\.com/[\w-]+"#,
        options: .caseInsensitive
    )
    private static let teamsPattern = try! NSRegularExpression(
        pattern: #"https?://teams\.microsoft\.com/l/meetup-join/[\w%/?.=&-]+"#,
        options: .caseInsensitive
    )

    func refreshCache() {
        GoogleAuthManager.shared.refreshTokenIfNeeded { [weak self] success in
            guard success, let token = GoogleAuthManager.shared.accessToken else {
                print("Failed to refresh Google token")
                return
            }
            self?.fetchUpcomingEvents(accessToken: token)
        }
    }

    func fetchCachedMeetings() -> [MeetingEvent] {
        return cachedMeetings
    }

    // MARK: - Feature 3: Calendar Weather Computation

    func computeWeather() -> CalendarWeather {
        let now = Date()
        let eightHoursLater = Calendar.current.date(byAdding: .hour, value: 8, to: now)!

        let upcoming = cachedMeetings.filter { meeting in
            !meeting.isAllDay && meeting.startTime >= now && meeting.startTime <= eightHoursLater
        }

        let totalMinutes = upcoming.reduce(0) { $0 + Int(($1.duration) / 60) }
        let totalHours = Double(totalMinutes) / 60.0

        // Check for back-to-back blocks (< 5 min gap)
        let sorted = upcoming.sorted { $0.startTime < $1.startTime }
        var backToBackCount = 0
        if sorted.count > 1 {
            for i in 0..<(sorted.count - 1) {
                let gap = sorted[i + 1].startTime.timeIntervalSince(sorted[i].endTime)
                if gap < 300 { // < 5 minutes
                    backToBackCount += 1
                }
            }
        }

        let weather: CalendarWeather
        if totalHours > 4 || backToBackCount >= 2 {
            weather = .stormWarning
        } else if totalHours >= 2 {
            weather = .overcast
        } else {
            weather = .clearSkies
        }

        DispatchQueue.main.async { [weak self] in
            self?.calendarWeather = weather
        }
        return weather
    }

    // MARK: - Feature 4: Conflict Detection

    func detectConflicts() -> [(MeetingEvent, MeetingEvent)] {
        let nonAllDay = cachedMeetings.filter { !$0.isAllDay && !$0.isPast }
        var foundConflicts: [(MeetingEvent, MeetingEvent)] = []

        for i in 0..<nonAllDay.count {
            for j in (i + 1)..<nonAllDay.count {
                if nonAllDay[i].overlaps(with: nonAllDay[j]) {
                    foundConflicts.append((nonAllDay[i], nonAllDay[j]))
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.conflicts = foundConflicts
        }
        return foundConflicts
    }

    // MARK: - Feature 5: Daily Metrics Computation

    func computeDailyMetrics(for date: Date = Date()) -> DailyMetrics {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let dayMeetings = cachedMeetings.filter { meeting in
            !meeting.isAllDay && calendar.isDate(meeting.startTime, inSameDayAs: date)
        }

        let totalMinutes = dayMeetings.reduce(0) { $0 + Int($1.duration / 60) }
        let deepWork = max(0, 480 - totalMinutes) // Assume 8hr workday

        let sorted = dayMeetings.sorted { $0.startTime < $1.startTime }
        var backToBack = 0
        if sorted.count > 1 {
            for i in 0..<(sorted.count - 1) {
                let gap = sorted[i + 1].startTime.timeIntervalSince(sorted[i].endTime)
                if gap < 300 { backToBack += 1 }
            }
        }

        return DailyMetrics(
            date: dateString,
            totalMeetingMinutes: totalMinutes,
            deepWorkMinutes: deepWork,
            backToBackBlocks: backToBack,
            earlyExits: 0,
            meetingCount: dayMeetings.count
        )
    }

    // MARK: - Smart URL Extraction (Feature 2)

    private func extractConferenceURL(from item: [String: Any]) -> (URL?, ConferencePlatform) {
        // Priority 1: conferenceData entryPoints
        if let entryPoints = (item["conferenceData"] as? [String: Any])?["entryPoints"] as? [[String: Any]] {
            if let videoEntry = entryPoints.first(where: { ($0["entryPointType"] as? String) == "video" }),
               let uri = videoEntry["uri"] as? String,
               let url = URL(string: uri) {
                return (url, detectPlatform(from: uri))
            }
        }

        // Priority 2: hangoutLink
        if let hangout = item["hangoutLink"] as? String, let url = URL(string: hangout) {
            return (url, .googleMeet)
        }

        // Priority 3: Scan location field
        if let location = item["location"] as? String {
            if let (url, platform) = extractURLFromText(location) {
                return (url, platform)
            }
        }

        // Priority 4: Scan description/body
        if let description = item["description"] as? String {
            if let (url, platform) = extractURLFromText(description) {
                return (url, platform)
            }
        }

        return (nil, .unknown)
    }

    private func extractURLFromText(_ text: String) -> (URL, ConferencePlatform)? {
        let range = NSRange(text.startIndex..., in: text)

        // Check Zoom
        if let match = Self.zoomPattern.firstMatch(in: text, range: range),
           let matchRange = Range(match.range, in: text) {
            let urlString = String(text[matchRange])
            if let url = URL(string: urlString) { return (url, .zoom) }
        }

        // Check Google Meet
        if let match = Self.meetPattern.firstMatch(in: text, range: range),
           let matchRange = Range(match.range, in: text) {
            let urlString = String(text[matchRange])
            if let url = URL(string: urlString) { return (url, .googleMeet) }
        }

        // Check Teams
        if let match = Self.teamsPattern.firstMatch(in: text, range: range),
           let matchRange = Range(match.range, in: text) {
            let urlString = String(text[matchRange])
            if let url = URL(string: urlString) { return (url, .teams) }
        }

        return nil
    }

    private func detectPlatform(from urlString: String) -> ConferencePlatform {
        let lower = urlString.lowercased()
        if lower.contains("zoom.us") { return .zoom }
        if lower.contains("meet.google.com") { return .googleMeet }
        if lower.contains("teams.microsoft.com") { return .teams }
        return .unknown
    }

    // MARK: - Fetch Events

    private func fetchUpcomingEvents(accessToken: String) {
        let now = Date()
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        let formatter = ISO8601DateFormatter()
        let timeMin = formatter.string(from: now)
        let timeMax = formatter.string(from: sevenDaysLater)

        var components = URLComponents(string: "\(GoogleOAuthConfig.calendarAPIBase)/calendars/primary/events")!
        components.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "50"),
            URLQueryItem(name: "conferenceDataVersion", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Calendar fetch error: \(error?.localizedDescription ?? "unknown")")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    let meetings = items.compactMap { item -> MeetingEvent? in
                        guard let id = item["id"] as? String,
                              let summary = item["summary"] as? String,
                              let start = item["start"] as? [String: Any],
                              let end = item["end"] as? [String: Any]
                        else { return nil }

                        let isAllDay = start["date"] != nil

                        let startDate = self.parseDate(from: start)
                        let endDate = self.parseDate(from: end)

                        guard let sDate = startDate, let eDate = endDate else { return nil }

                        var attendees: [Attendee] = []
                        if let attendeeList = item["attendees"] as? [[String: Any]] {
                            attendees = attendeeList.compactMap { a in
                                guard let email = a["email"] as? String else { return nil }
                                let name = (a["displayName"] as? String) ?? email.components(separatedBy: "@").first ?? email
                                let statusStr = (a["responseStatus"] as? String) ?? "needsAction"
                                let status: AttendeeStatus
                                switch statusStr {
                                case "accepted": status = .accepted
                                case "declined": status = .declined
                                case "tentative": status = .tentative
                                default: status = .needsAction
                                }
                                return Attendee(name: name, email: email, status: status)
                            }
                        }

                        // Feature 2: Smart URL extraction
                        let (confURL, platform) = self.extractConferenceURL(from: item)

                        let location = item["location"] as? String
                        let description = item["description"] as? String

                        return MeetingEvent(
                            id: id,
                            title: summary,
                            startTime: sDate,
                            endTime: eDate,
                            conferenceURL: confURL,
                            location: location,
                            attendees: attendees,
                            calendarColor: nil,
                            description: description,
                            isAllDay: isAllDay,
                            platform: platform
                        )
                    }

                    DispatchQueue.main.async {
                        self.cachedMeetings = meetings
                        self.meetings = meetings
                        _ = self.computeWeather()
                        _ = self.detectConflicts()
                    }
                }
            } catch {
                print("JSON parse error: \(error)")
            }
        }.resume()
    }

    private func parseDate(from dict: [String: Any]) -> Date? {
        if let dateTimeStr = dict["dateTime"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = formatter.date(from: dateTimeStr) { return d }
            let basic = ISO8601DateFormatter()
            return basic.date(from: dateTimeStr)
        } else if let dateStr = dict["date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateStr)
        }
        return nil
    }
}
