import SwiftUI
import AppKit

// MARK: - Feature 1: Boarding Pass Departure Board Dashboard

struct MeetingsDashboardView: View {
    @ObservedObject var calendarManager: CalendarManager
    @State private var hoveredMeetingID: String? = nil
    @State private var showAnalytics = true
    @State private var showConflicts = false

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
            DepartureHeaderView(
                weather: calendarManager.calendarWeather,
                conflictCount: calendarManager.conflicts.count,
                onRefresh: { calendarManager.refreshCache() },
                onToggleAnalytics: { showAnalytics.toggle() },
                onToggleConflicts: { showConflicts.toggle() }
            )

            if showAnalytics {
                FlightRecorderView(calendarManager: calendarManager)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Hardware status bar
            SystemStatusBar()

            if showConflicts && !calendarManager.conflicts.isEmpty {
                ConflictAlertView(conflicts: calendarManager.conflicts)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if calendarManager.meetings.isEmpty {
                EmptyRunwayView()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedMeetings, id: \.0) { dateKey, meetings in
                            Section(header: TerminalGateHeader(dateString: dateKey, meetingCount: meetings.count)) {
                                VStack(spacing: 12) {
                                    ForEach(meetings) { meeting in
                                        BoardingPassCard(
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

            DepartureFooterView(
                totalMeetings: calendarManager.meetings.count,
                weather: calendarManager.calendarWeather
            )
        }
        .frame(width: 520, height: 640)
        .background(Color(red: 0.06, green: 0.07, blue: 0.1))
    }
}

// MARK: - Departure Board Header

struct DepartureHeaderView: View {
    let weather: CalendarWeather
    let conflictCount: Int
    let onRefresh: () -> Void
    let onToggleAnalytics: () -> Void
    let onToggleConflicts: () -> Void
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 0) {
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
                        Image(systemName: weather.menuBarIcon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("RUNWAY")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(2)
                        Text("MEETING BOARD")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                            .tracking(1)
                    }
                }

                Spacer()

                // Weather indicator
                HStack(spacing: 6) {
                    Image(systemName: weather.icon)
                        .font(.system(size: 11))
                        .foregroundColor(weatherColor)
                    Text(weather.description.components(separatedBy: " - ").last ?? "")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(weatherColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(weatherColor.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(weatherColor.opacity(0.3), lineWidth: 0.5))
                )

                // Conflict indicator
                if conflictCount > 0 {
                    Button(action: onToggleConflicts) {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("ATC \(conflictCount)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.orange.opacity(0.3), lineWidth: 0.5))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Analytics button
                Button(action: onToggleAnalytics) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)

                // Refresh
                Button(action: {
                    isRefreshing = true
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { isRefreshing = false }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 0.6).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Departure board divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.5), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.13))
    }

    private var weatherColor: Color {
        switch weather {
        case .clearSkies: return .green
        case .overcast: return .yellow
        case .stormWarning: return .red
        }
    }
}

// MARK: - Terminal Gate Header (Day Separator)

struct TerminalGateHeader: View {
    let dateString: String
    let meetingCount: Int

    private var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "TODAY" }
        if calendar.isDateInTomorrow(date) { return "TOMORROW" }
        let display = DateFormatter()
        display.dateFormat = "EEE, MMM d"
        return display.string(from: date).uppercased()
    }

    private var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("GATE")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                .tracking(1)

            Text(displayDate)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(isToday ? Color(red: 0.3, green: 0.8, blue: 0.5) : .white)
                .tracking(0.5)

            Text("\(meetingCount) MEETING\(meetingCount == 1 ? "" : "S")")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.05))
                )

            Spacer()

            // Blinking dot for today
            if isToday {
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.06, green: 0.07, blue: 0.1).opacity(0.98))
    }
}

// MARK: - Feature 1: Boarding Pass Card

struct BoardingPassCard: View {
    let meeting: MeetingEvent
    let isHovered: Bool

    @State private var pulseOpacity: Double = 1.0
    let pulseTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

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

    private var roomName: String? {
        if let location = meeting.location, !location.isEmpty {
            return location
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
                // MAIN CONTENT
                HStack(spacing: 0) {
                    // LEFT: Time column
                    VStack(spacing: 4) {
                        Text(startTimeText)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Rectangle()
                            .fill(urgencyColor.opacity(0.4))
                            .frame(width: 1, height: 16)
                        
                        Text(endTimeText)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                    }
                    .frame(width: 72)
                    .padding(.vertical, 14)

                    // ACCENT BAR
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [urgencyColor, urgencyColor.opacity(0.4)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 3)
                        .padding(.vertical, 10)

                    // CENTER: Meeting details
                    VStack(alignment: .leading, spacing: 8) {
                        // Title + badge row
                        HStack(spacing: 8) {
                            Text(meeting.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            urgencyBadge
                        }

                        // Info chips row
                        HStack(spacing: 8) {
                            // Duration chip
                            InfoChip(icon: "clock", text: meeting.durationFormatted)

                            // Attendees
                            if !meeting.attendees.isEmpty {
                                InfoChip(icon: "person.2", text: "\(meeting.attendees.count)")
                            }

                            // Platform
                            if meeting.conferenceURL != nil {
                                InfoChip(
                                    icon: meeting.platform.iconName,
                                    text: meeting.platform.displayName,
                                    tint: Color(red: 0.3, green: 0.6, blue: 1.0)
                                )
                            }

                            Spacer()
                        }

                        // Room / Location row (shown inline, truncated nicely)
                        if let room = roomName {
                            HStack(spacing: 5) {
                                Image(systemName: "door.left.hand.open")
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                                Text(room)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.85))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)

                    // RIGHT: Action button
                    if let url = meeting.conferenceURL {
                        VStack {
                            Spacer()
                            Button(action: { NSWorkspace.shared.open(url) }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            meeting.isHappening
                                            ? Color.green
                                            : Color(red: 0.22, green: 0.42, blue: 0.95)
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    VStack(spacing: 2) {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("JOIN")
                                            .font(.system(size: 7, weight: .black, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(isHovered || meeting.isHappening ? 1.0 : 0.6)
                            Spacer()
                        }
                        .padding(.trailing, 12)
                    }
                }

                // EXPANDED ATTENDEES (on hover)
                if isHovered && !meeting.attendees.isEmpty {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    HStack(spacing: 0) {
                        HStack(spacing: -6) {
                            ForEach(Array(meeting.attendees.prefix(5).enumerated()), id: \.offset) { _, attendee in
                                AvatarCircle(attendee: attendee)
                            }
                        }

                        if meeting.attendees.count > 5 {
                            Text("+\(meeting.attendees.count - 5)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .padding(.leading, 8)
                        }

                        Spacer()

                        let accepted = meeting.attendees.filter { $0.status == .accepted }.count
                        if accepted > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.green)
                                Text("\(accepted) accepted")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(cardBorderColor, lineWidth: isHovered ? 1.2 : 0.7)
                )
        )
        .shadow(
            color: cardGlowColor.opacity(isHovered ? 0.15 : 0.03),
            radius: isHovered ? 16 : 6,
            x: 0, y: isHovered ? 6 : 2
        )
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .opacity(meeting.isPast ? 0.35 : 1.0)
        .onReceive(pulseTimer) { _ in
            if meeting.urgency == .boardingNow {
                pulseOpacity = pulseOpacity == 1.0 ? 0.5 : 1.0
            }
        }
    }

    @ViewBuilder
    private var urgencyBadge: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 5, height: 5)
                .opacity(meeting.urgency == .boardingNow ? pulseOpacity : 1.0)
            Text(urgencyText)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(urgencyColor)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(urgencyColor.opacity(0.1))
                .overlay(Capsule().stroke(urgencyColor.opacity(0.2), lineWidth: 0.5))
        )
    }

    private var urgencyText: String {
        switch meeting.urgency {
        case .scheduled: return "UPCOMING"
        case .boardingNow: return "STARTING SOON"
        case .inProgress: return "IN PROGRESS"
        case .past: return "ENDED"
        }
    }

    private var urgencyColor: Color {
        switch meeting.urgency {
        case .scheduled: return .green
        case .boardingNow: return .yellow
        case .inProgress: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .past: return .gray
        }
    }

    private var cardBackground: Color {
        switch meeting.urgency {
        case .scheduled: return Color(red: 0.08, green: 0.1, blue: 0.14)
        case .boardingNow: return Color(red: 0.12, green: 0.11, blue: 0.06)
        case .inProgress: return Color(red: 0.06, green: 0.1, blue: 0.14)
        case .past: return Color(red: 0.07, green: 0.07, blue: 0.08)
        }
    }

    private var cardBorderColor: Color {
        switch meeting.urgency {
        case .scheduled: return Color.green.opacity(0.2)
        case .boardingNow: return Color.yellow.opacity(0.3)
        case .inProgress: return Color.blue.opacity(0.3)
        case .past: return Color.gray.opacity(0.1)
        }
    }

    private var cardGlowColor: Color {
        switch meeting.urgency {
        case .scheduled: return .green
        case .boardingNow: return .yellow
        case .inProgress: return .blue
        case .past: return .clear
        }
    }
}

// MARK: - Dashed Separator (Boarding Pass tear-off line)

struct DashedSeparator: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let dashHeight: CGFloat = 4
                let gap: CGFloat = 4
                var y: CGFloat = 0
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: 0, y: min(y + dashHeight, geometry.size.height)))
                    y += dashHeight + gap
                }
            }
            .stroke(Color(red: 0.3, green: 0.35, blue: 0.45), lineWidth: 1)
        }
    }
}

// MARK: - Info Chip

struct InfoChip: View {
    let icon: String
    let text: String
    var tint: Color = Color(red: 0.5, green: 0.6, blue: 0.7)

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(text)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(tint.opacity(0.08))
        )
    }
}

// MARK: - Avatar Circle

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
                .frame(width: 24, height: 24)
            Text(initials)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(Color(red: 0.08, green: 0.09, blue: 0.12), lineWidth: 2)
        )
    }
}

// MARK: - Feature 4: Conflict Alert View

struct ConflictAlertView: View {
    let conflicts: [(MeetingEvent, MeetingEvent)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                Text("ATC ALERT: FLIGHT CONFLICTS DETECTED")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                    .tracking(0.5)
                Spacer()
            }

            ForEach(Array(conflicts.prefix(3).enumerated()), id: \.offset) { _, conflict in
                HStack(spacing: 8) {
                    Text(conflict.0.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.orange)
                    Text(conflict.1.title)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.2), lineWidth: 0.5))
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - Feature 5: Meeting Analytics (Flight Recorder)

struct FlightRecorderView: View {
    @ObservedObject var calendarManager: CalendarManager

    private var metrics: DailyMetrics {
        calendarManager.computeDailyMetrics()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                Text("TODAY'S FLIGHT LOG")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                    .tracking(0.5)
                Spacer()
            }

            HStack(spacing: 12) {
                MetricBox(
                    label: "IN MEETINGS",
                    value: String(format: "%.1fh", metrics.airTimeHours),
                    icon: "clock.fill",
                    color: .blue
                )
                MetricBox(
                    label: "BACK-TO-BACK",
                    value: "\(metrics.turbulenceScore)",
                    icon: "exclamationmark.2",
                    color: metrics.turbulenceScore > 2 ? .red : .yellow
                )
                MetricBox(
                    label: "FOCUS TIME",
                    value: "\(metrics.deepWorkMinutes / 60)h",
                    icon: "brain.head.profile",
                    color: .green
                )
                MetricBox(
                    label: "MEETINGS",
                    value: "\(metrics.meetingCount)",
                    icon: "calendar",
                    color: .purple
                )
            }

            // Bar chart
            if metrics.totalMeetingMinutes > 0 {
                GeometryReader { geo in
                    let meetingRatio = CGFloat(metrics.totalMeetingMinutes) / 480.0
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.6))
                            .frame(width: geo.size.width * min(meetingRatio, 1.0))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(0.3))
                            .frame(width: geo.size.width * max(1.0 - meetingRatio, 0))
                    }
                }
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))

                HStack {
                    Text("Meetings")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.blue)
                    Spacer()
                    Text("Focus Time")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.06, green: 0.08, blue: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.2, green: 0.3, blue: 0.5).opacity(0.3), lineWidth: 0.5))
        )
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - System Status Bar (Feature 11: Hardware Status)

struct SystemStatusBar: View {
    @State private var status: HardwareStatus = HardwareStatus()

    var body: some View {
        HStack(spacing: 12) {
            Text("PRE-FLIGHT CHECK")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                .tracking(0.5)

            Spacer()

            // Mic status
            StatusIndicator(
                icon: status.isMicMuted ? "mic.slash.fill" : "mic.fill",
                label: status.isMicMuted ? "MUTED" : "MIC OK",
                isWarning: status.isMicMuted
            )

            // Bluetooth/Audio
            StatusIndicator(
                icon: status.isHeadsetDisconnected ? "headphones" : "headphones",
                label: status.isHeadsetDisconnected ? "NO AUDIO" : "AUDIO OK",
                isWarning: status.isHeadsetDisconnected
            )

            // Battery
            StatusIndicator(
                icon: status.isBatteryCritical ? "battery.25" : "battery.100",
                label: "\(status.batteryLevel)%",
                isWarning: status.isBatteryCritical
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(red: 0.05, green: 0.06, blue: 0.09))
        .onAppear {
            status = OverlayController.shared.performPreFlightCheck()
        }
    }
}

struct StatusIndicator: View {
    let icon: String
    let label: String
    let isWarning: Bool

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
        }
        .foregroundColor(isWarning ? .orange : Color(red: 0.4, green: 0.7, blue: 0.4))
    }
}

struct MetricBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.05))
        )
    }
}

// MARK: - Empty State

struct EmptyRunwayView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 38, weight: .thin))
                    .foregroundColor(.green.opacity(0.5))
            }
            Text("ALL CLEAR")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .tracking(2)
            Text("No meetings scheduled in the next 7 days.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Footer

struct DepartureFooterView: View {
    let totalMeetings: Int
    let weather: CalendarWeather

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, Color(red: 0.3, green: 0.4, blue: 0.6).opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)

        HStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
                Text("SYNCED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.4))
                    .tracking(0.5)
            }
            Spacer()
            Text("\(totalMeetings) MEETINGS | 7 DAY WINDOW")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                .tracking(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.05, green: 0.06, blue: 0.08))
    }
}
