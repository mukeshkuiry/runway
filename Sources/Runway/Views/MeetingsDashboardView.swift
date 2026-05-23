import SwiftUI
import AppKit

struct MeetingsDashboardView: View {
    @ObservedObject var calendarManager: CalendarManager

    @State private var hoveredMeetingID: String? = nil

    private var groupedMeetings: [(String, [MeetingEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let grouped = Dictionary(grouping: calendarManager.meetings) { meeting in
            formatter.string(from: meeting.startTime)
        }

        return grouped.sorted { $0.key < $1.key }.map { (key, events) in
            (key, events.sorted { $0.startTime < $1.startTime })
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            DashboardHeaderView(onRefresh: { calendarManager.refreshCache() })

            if calendarManager.meetings.isEmpty {
                EmptyStateView()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedMeetings, id: \.0) { dateKey, meetings in
                            Section(header: DayHeaderView(dateString: dateKey, meetingCount: meetings.count)) {
                                VStack(spacing: 10) {
                                    ForEach(meetings) { meeting in
                                        MeetingCardView(
                                            meeting: meeting,
                                            isHovered: hoveredMeetingID == meeting.id
                                        )
                                        .onHover { hovering in
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                hoveredMeetingID = hovering ? meeting.id : nil
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }

            DashboardFooterView(totalMeetings: calendarManager.meetings.count)
        }
        .frame(width: 500, height: 640)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Header

struct DashboardHeaderView: View {
    let onRefresh: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.22, green: 0.42, blue: 0.95), Color(red: 0.38, green: 0.28, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Runway")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("Your meetings, at a glance")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(Date(), format: .dateTime.weekday(.wide))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(Date(), format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }

            Button(action: {
                isRefreshing = true
                onRefresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isRefreshing = false }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 28, height: 28)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Day Header

struct DayHeaderView: View {
    let dateString: String
    let meetingCount: Int

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let display = DateFormatter()
        display.dateFormat = "EEEE, MMM d"
        return display.string(from: date)
    }

    private var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack(spacing: 8) {
            if isToday {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.22, green: 0.42, blue: 0.95))
                    .frame(width: 3, height: 14)
            }

            Text(displayDate)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(isToday ? Color(red: 0.22, green: 0.42, blue: 0.95) : .primary)

            Text("\(meetingCount) meeting\(meetingCount == 1 ? "" : "s")")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.primary.opacity(0.05)))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }
}

// MARK: - Meeting Card

struct MeetingCardView: View {
    let meeting: MeetingEvent
    let isHovered: Bool

    private var startTimeText: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: meeting.startTime)
    }

    private var endTimeText: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: meeting.endTime)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 14) {
                // Left color accent
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: statusGradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, 4)

                // Time block
                VStack(alignment: .center, spacing: 2) {
                    if meeting.isAllDay {
                        Text("ALL DAY")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    } else {
                        Text(startTimeText)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .fixedSize()
                        Text(endTimeText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .fixedSize()
                    }
                }
                .frame(width: 68)

                // Content
                VStack(alignment: .leading, spacing: 5) {
                    // Title row
                    HStack(spacing: 8) {
                        Text(meeting.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        if meeting.isHappening {
                            StatusBadge(text: "LIVE", color: .green)
                        } else if !meeting.isPast && meeting.minutesUntilStart >= 0 && meeting.minutesUntilStart <= 5 {
                            StatusBadge(text: "SOON", color: .orange)
                        }
                    }

                    // Meta row
                    HStack(spacing: 14) {
                        MetaLabel(icon: "clock", text: meeting.durationFormatted)

                        if !meeting.attendees.isEmpty {
                            MetaLabel(icon: "person.2.fill", text: "\(meeting.attendees.count)")
                        }

                        if meeting.conferenceURL != nil {
                            MetaLabel(icon: "video.fill", text: "Video", tint: Color(red: 0.22, green: 0.42, blue: 0.95))
                        }

                        if let location = meeting.location, !location.isEmpty {
                            MetaLabel(icon: "location.fill", text: location)
                        }
                    }
                }

                // Join button
                if let url = meeting.conferenceURL {
                    Button(action: { NSWorkspace.shared.open(url) }) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(meeting.isHappening ? Color.green : Color(red: 0.22, green: 0.42, blue: 0.95))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(isHovered || meeting.isHappening ? 1.0 : 0.0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Expanded attendee section on hover
            if isHovered && !meeting.attendees.isEmpty {
                Divider()
                    .padding(.horizontal, 14)

                HStack(spacing: 0) {
                    // Attendee avatars
                    HStack(spacing: -8) {
                        ForEach(Array(meeting.attendees.prefix(6).enumerated()), id: \.offset) { _, attendee in
                            AvatarCircle(attendee: attendee)
                        }
                    }

                    if meeting.attendees.count > 6 {
                        Text("+\(meeting.attendees.count - 6) more")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.leading, 10)
                    }

                    Spacer()

                    // Accepted count
                    let accepted = meeting.attendees.filter { $0.status == .accepted }.count
                    if accepted > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text("\(accepted) accepted")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    meeting.isHappening ? Color.green.opacity(0.4) :
                        (isHovered ? Color.primary.opacity(0.08) : Color.primary.opacity(0.04)),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isHovered ? Color.primary.opacity(0.06) : Color.clear,
            radius: isHovered ? 8 : 0,
            x: 0, y: isHovered ? 3 : 0
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .opacity(meeting.isPast ? 0.4 : 1.0)
    }

    private var statusGradient: [Color] {
        if meeting.isHappening { return [.green, .green.opacity(0.5)] }
        if meeting.isPast { return [.gray.opacity(0.2), .gray.opacity(0.1)] }
        if meeting.minutesUntilStart <= 5 { return [.orange, .orange.opacity(0.5)] }
        return [Color(red: 0.22, green: 0.42, blue: 0.95), Color(red: 0.38, green: 0.28, blue: 0.88)]
    }
}

// MARK: - Sub-components

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Capsule().fill(color))
    }
}

struct MetaLabel: View {
    let icon: String
    let text: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(tint)
    }
}

struct AvatarCircle: View {
    let attendee: Attendee

    private var initials: String {
        let parts = attendee.name.components(separatedBy: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [
            Color(red: 0.22, green: 0.42, blue: 0.95),
            Color(red: 0.6, green: 0.3, blue: 0.85),
            Color(red: 0.1, green: 0.7, blue: 0.5),
            Color(red: 0.9, green: 0.45, blue: 0.2),
            Color(red: 0.85, green: 0.25, blue: 0.4),
            Color(red: 0.2, green: 0.6, blue: 0.7),
            Color(red: 0.5, green: 0.3, blue: 0.7)
        ]
        let hash = abs(attendee.email.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: 26, height: 26)
            Text(initials)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 2)
        )
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(red: 0.22, green: 0.42, blue: 0.95).opacity(0.06))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 38, weight: .thin))
                    .foregroundColor(Color(red: 0.22, green: 0.42, blue: 0.95).opacity(0.5))
            }

            Text("All Clear")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text("No meetings in the next 7 days.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Footer

struct DashboardFooterView: View {
    let totalMeetings: Int

    var body: some View {
        Divider().opacity(0.5)
        HStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("Synced with Google Calendar")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(totalMeetings) meetings · Next 7 days")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
    }
}
