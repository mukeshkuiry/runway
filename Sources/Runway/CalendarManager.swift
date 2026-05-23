import Foundation

/// Fetches upcoming events from Google Calendar API
final class CalendarManager: ObservableObject {
    @Published var meetings: [MeetingEvent] = []
    private var cachedMeetings: [MeetingEvent] = []

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

    private func fetchUpcomingEvents(accessToken: String) {
        let now = Date()
        // Fetch 7 days of events
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
            URLQueryItem(name: "maxResults", value: "50")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else {
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

                        let startDate = self?.parseDate(from: start)
                        let endDate = self?.parseDate(from: end)

                        guard let sDate = startDate, let eDate = endDate else { return nil }

                        // Parse attendees
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

                        // Conference URL
                        var confURL: URL? = nil
                        if let entryPoints = (item["conferenceData"] as? [String: Any])?["entryPoints"] as? [[String: Any]] {
                            if let videoEntry = entryPoints.first(where: { ($0["entryPointType"] as? String) == "video" }),
                               let uri = videoEntry["uri"] as? String {
                                confURL = URL(string: uri)
                            }
                        }
                        if confURL == nil, let hangout = item["hangoutLink"] as? String {
                            confURL = URL(string: hangout)
                        }

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
                            isAllDay: isAllDay
                        )
                    }

                    DispatchQueue.main.async {
                        self?.cachedMeetings = meetings
                        self?.meetings = meetings
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
