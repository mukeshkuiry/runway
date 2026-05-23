import SwiftUI
import AppKit

// MARK: - Feature 7: Three-Stage Countdown Pipeline
// T-5: Calm horizontal flight (ReminderAlertView)
// T-2: Turbulent shaking flight (TurbulentAlertView)
// T-0: Nose-dive crash landing (CrashLandingAlertView)

// MARK: - Feature 8: Aircraft Customization by Keyword

/// T-5 Minutes: Standard calm flight towing a banner
struct ReminderAlertView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void
    var hardwareWarnings: [String] = []

    @State private var positionX: CGFloat = -500
    @State private var engineGlow: Double = 0.6
    @State private var bannerWave: CGFloat = 0
    @State private var interactable: Bool = false

    let animTimer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    private var aircraft: AircraftType { meeting.aircraftType }
    private var transitDuration: Double { aircraft.transitDuration }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.startTime)
    }

    var body: some View {
        ZStack {
            Color.clear

            HStack(spacing: 0) {
                // === THE AIRCRAFT (Feature 8) ===
                aircraftView

                // === TOW CABLE ===
                TowCable()
                    .stroke(
                        Color(red: 0.4, green: 0.4, blue: 0.45),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 50, height: 20)

                // === BANNER ===
                bannerView
            }
            .position(x: positionX, y: aircraft == .blimp ? 60 : screenHeight * 0.42)
        }
        .onReceive(animTimer) { _ in
            engineGlow = Double.random(in: 0.5...0.9)
            bannerWave = sin(Date().timeIntervalSinceReferenceDate * 2.5) * 2

            // Feature 9: Option key detection for click-to-board
            interactable = NSEvent.modifierFlags.contains(.option)
        }
        .onAppear {
            let center = screenWidth / 2
            let flyIn = transitDuration * 0.4
            let holdTime = transitDuration * 1.2
            let flyOut = transitDuration * 0.4

            // Phase 1: Fly in
            withAnimation(.easeOut(duration: flyIn)) {
                positionX = center
            }

            // Phase 2: Hold then fly out
            DispatchQueue.main.asyncAfter(deadline: .now() + flyIn + holdTime) {
                withAnimation(.easeIn(duration: flyOut)) {
                    positionX = screenWidth + 500
                }
            }

            // Phase 3: Dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + flyIn + holdTime + flyOut + 0.1) {
                completion()
            }
        }
    }

    // MARK: - Aircraft Views (Feature 8)

    @ViewBuilder
    private var aircraftView: some View {
        switch aircraft {
        case .biplane:
            BiplaneView(engineGlow: engineGlow)
        case .passengerJet:
            JetView(engineGlow: engineGlow, tintColor: Color(red: 0.95, green: 0.96, blue: 0.98))
        case .rocket:
            RocketView(engineGlow: engineGlow)
        case .blimp:
            BlimpView(engineGlow: engineGlow)
        }
    }

    @ViewBuilder
    private var bannerView: some View {
        HStack(spacing: 12) {
            // Platform icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: meeting.platform.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.25, green: 0.45, blue: 0.95))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("in 5 minutes")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.5))

                Text(meeting.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Feature 11: Hardware warnings
                if !hardwareWarnings.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(hardwareWarnings, id: \.self) { warning in
                            Text("\u{26A0}\u{FE0F} \(warning)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            Spacer().frame(width: 8)

            Text(timeText)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.7, blue: 1.0))

            // Feature 9: Click to board indicator
            if interactable, meeting.conferenceURL != nil {
                Button(action: {
                    if let url = meeting.conferenceURL {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("BOARD")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.green))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.18))
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .offset(y: bannerWave)
    }
}

// MARK: - T-2 Minutes: Turbulent Flight (Feature 7)

struct TurbulentAlertView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void
    var hardwareWarnings: [String] = []

    @State private var positionX: CGFloat = -500
    @State private var shakeY: CGFloat = 0  // kept for position, no shake
    @State private var engineGlow: Double = 0.8
    @State private var smokeOpacity: Double = 0.6
    @State private var interactable: Bool = false

    let animTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect() // 30Hz

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.startTime)
    }

    var body: some View {
        ZStack {
            Color.clear

            HStack(spacing: 0) {
                // Smoke trail
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(Color.gray.opacity(smokeOpacity * Double(5 - i) / 5.0))
                            .frame(width: CGFloat(10 + i * 6), height: CGFloat(10 + i * 6))
                            .offset(x: CGFloat(-30 - i * 20), y: CGFloat.random(in: -5...5))
                    }
                }

                // Aircraft (always rocket-style for turbulence)
                JetView(engineGlow: engineGlow, tintColor: Color(red: 0.95, green: 0.9, blue: 0.88))

                // Tow cable
                TowCable()
                    .stroke(
                        Color(red: 0.5, green: 0.35, blue: 0.35),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 40, height: 20)

                // Urgent banner
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("T-2 MINUTES")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                            .tracking(0.8)

                        Text(meeting.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if !hardwareWarnings.isEmpty {
                            Text(hardwareWarnings.map { "\u{26A0}\u{FE0F} \($0)" }.joined(separator: " | "))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer().frame(width: 8)

                    if interactable, let url = meeting.conferenceURL {
                        Button(action: { NSWorkspace.shared.open(url) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("BOARD")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.green))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.15, green: 0.12, blue: 0.08))
                        .shadow(color: .orange.opacity(0.2), radius: 16, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
            }
            .position(x: positionX, y: screenHeight * 0.42 + shakeY)
        }
        .onReceive(animTimer) { _ in
            engineGlow = Double.random(in: 0.6...1.0)
            smokeOpacity = Double.random(in: 0.4...0.8)
            interactable = NSEvent.modifierFlags.contains(.option)
        }
        .onAppear {
            let center = screenWidth / 2

            withAnimation(.easeOut(duration: 2.0)) {
                positionX = center
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                withAnimation(.easeIn(duration: 2.0)) {
                    positionX = screenWidth + 500
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 9.1) {
                completion()
            }
        }
    }
}

// MARK: - T-0 Minutes: Meeting Starting Now (Feature 7) — Clean urgent notification

struct CrashLandingAlertView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void

    @State private var cardScale: CGFloat = 0.8
    @State private var cardOpacity: Double = 0
    @State private var pulseRing: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.8
    @State private var dismissOpacity: Double = 1.0

    let pulseTimer = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()
    @State private var pulseToggle = false

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: meeting.startTime)
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 16) {
                // Pulsing urgency ring
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(pulseOpacity * 0.3), lineWidth: 2)
                        .frame(width: 80 * pulseRing, height: 80 * pulseRing)

                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: "bell.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                }

                VStack(spacing: 6) {
                    Text("MEETING STARTING NOW")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.red)
                        .tracking(1)

                    Text(meeting.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(timeText)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.8))
                }

                if let url = meeting.conferenceURL {
                    Button(action: { NSWorkspace.shared.open(url) }) {
                        HStack(spacing: 8) {
                            Image(systemName: meeting.platform.iconName)
                                .font(.system(size: 13, weight: .bold))
                            Text("Join \(meeting.platform.displayName)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.13))
                    .shadow(color: .red.opacity(0.2), radius: 24, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(cardScale)
            .opacity(cardOpacity * dismissOpacity)
            .position(x: screenWidth / 2, y: screenHeight / 2)
        }
        .onReceive(pulseTimer) { _ in
            pulseToggle.toggle()
            withAnimation(.easeInOut(duration: 0.8)) {
                pulseRing = pulseToggle ? 1.3 : 1.0
                pulseOpacity = pulseToggle ? 0.3 : 0.8
            }
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }

            // Auto-dismiss after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    dismissOpacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.6) {
                completion()
            }
        }
    }
}

// MARK: - Feature 10: Autopilot Warning View

struct AutopilotWarningView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void

    @State private var positionX: CGFloat = -500

    var body: some View {
        ZStack {
            Color.clear

            HStack(spacing: 0) {
                JetView(engineGlow: 0.7, tintColor: Color(red: 0.9, green: 0.95, blue: 1.0))

                TowCable()
                    .stroke(Color.blue.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 40, height: 20)

                HStack(spacing: 10) {
                    Image(systemName: "autopilot")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("Autopilot Engaged: Launching Video Call in 15s")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.05, green: 0.1, blue: 0.2))
                        .shadow(color: .cyan.opacity(0.3), radius: 10)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                )
            }
            .position(x: positionX, y: screenHeight * 0.3)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                positionX = screenWidth / 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                withAnimation(.easeIn(duration: 2.0)) {
                    positionX = screenWidth + 500
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.1) {
                completion()
            }
        }
    }
}

// MARK: - Feature 13: Ejection Seat View

struct EjectionSeatView: View {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void

    @State private var seatY: CGFloat = 0
    @State private var seatOpacity: Double = 1.0

    var body: some View {
        ZStack {
            Color.clear

            // Ejection seat flying up
            VStack(spacing: 4) {
                // Pilot
                ZStack {
                    // Helmet
                    Circle()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.35))
                        .frame(width: 24, height: 24)
                    // Visor
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.7))
                        .frame(width: 16, height: 8)
                        .offset(y: 2)
                }

                // Seat
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.4, green: 0.35, blue: 0.3))
                    .frame(width: 30, height: 40)

                // Rocket flames
                ForEach(0..<3, id: \.self) { i in
                    Triangle()
                        .fill([Color.orange, Color.red, Color.yellow][i])
                        .frame(width: CGFloat(12 - i * 2), height: CGFloat(20 + i * 8))
                        .offset(x: CGFloat([-5, 5, 0][i]))
                }
            }
            .position(x: screenWidth / 2, y: seatY)
            .opacity(seatOpacity)
        }
        .onAppear {
            seatY = screenHeight + 50

            withAnimation(.easeOut(duration: 1.5)) {
                seatY = -100
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    seatOpacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                completion()
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - Feature 8: Aircraft Sprite Views

struct BiplaneView: View {
    let engineGlow: Double

    var body: some View {
        ZStack {
            // Contrail - light
            ContrailShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0)],
                        startPoint: .trailing, endPoint: .leading
                    )
                )
                .frame(width: 120, height: 6)
                .offset(x: -80, y: 5)

            // Body - vintage feel
            BiplaneSpriteShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.7, blue: 0.4), Color(red: 0.7, green: 0.55, blue: 0.3)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 100, height: 55)

            BiplaneSpriteShape()
                .stroke(Color(red: 0.5, green: 0.4, blue: 0.2), lineWidth: 1)
                .frame(width: 100, height: 55)

            // Propeller
            Ellipse()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 4, height: 20)
                .offset(x: 48)
        }
    }
}

struct JetView: View {
    let engineGlow: Double
    let tintColor: Color

    var body: some View {
        ZStack {
            // Contrail
            ContrailShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                        startPoint: .trailing, endPoint: .leading
                    )
                )
                .frame(width: 180, height: 8)
                .offset(x: -120, y: 8)

            // Plane body
            JetPlaneShape()
                .fill(
                    LinearGradient(
                        colors: [tintColor, tintColor.opacity(0.8)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 50)

            JetPlaneShape()
                .stroke(Color(red: 0.5, green: 0.55, blue: 0.6), lineWidth: 1.2)
                .frame(width: 120, height: 50)

            // Windows
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.55, green: 0.75, blue: 0.95))
                        .frame(width: 4, height: 4)
                }
            }
            .offset(x: 5, y: 2)

            // Cockpit
            CockpitShape()
                .fill(Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.8))
                .frame(width: 16, height: 10)
                .offset(x: 48, y: 0)

            // Engine glow
            Ellipse()
                .fill(Color.blue.opacity(engineGlow * 0.3))
                .frame(width: 14, height: 8)
                .offset(x: -55, y: 12)
        }
    }
}

struct RocketView: View {
    let engineGlow: Double

    var body: some View {
        ZStack {
            // Intense flame trail
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .fill(Color.orange.opacity(Double(6 - i) / 8.0))
                    .frame(width: CGFloat(8 + i * 8), height: CGFloat(6 + i * 3))
                    .offset(x: CGFloat(-50 - i * 15), y: 0)
            }

            // Rocket body - sleek and pointed
            RocketSpriteShape()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.8, green: 0.8, blue: 0.85)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 110, height: 35)

            RocketSpriteShape()
                .stroke(Color(red: 0.4, green: 0.4, blue: 0.5), lineWidth: 1)
                .frame(width: 110, height: 35)

            // Red accent
            Rectangle()
                .fill(Color.red)
                .frame(width: 50, height: 3)
                .offset(x: 0, y: 0)

            // Engine fire
            Ellipse()
                .fill(Color.red.opacity(engineGlow * 0.6))
                .frame(width: 16, height: 12)
                .offset(x: -52, y: 0)
        }
    }
}

struct BlimpView: View {
    let engineGlow: Double

    var body: some View {
        ZStack {
            // Blimp body - large oval
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.6, green: 0.65, blue: 0.75), Color(red: 0.4, green: 0.45, blue: 0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 60)

            Ellipse()
                .stroke(Color(red: 0.3, green: 0.35, blue: 0.45), lineWidth: 1.5)
                .frame(width: 160, height: 60)

            // Gondola
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.3, green: 0.3, blue: 0.35))
                .frame(width: 40, height: 14)
                .offset(y: 35)

            // Lines connecting gondola
            Path { path in
                path.move(to: CGPoint(x: -10, y: 28))
                path.addLine(to: CGPoint(x: -15, y: 35))
                path.move(to: CGPoint(x: 10, y: 28))
                path.addLine(to: CGPoint(x: 15, y: 35))
            }
            .stroke(Color.gray.opacity(0.5), lineWidth: 0.8)

            // Stripe
            Rectangle()
                .fill(Color(red: 0.2, green: 0.4, blue: 0.8).opacity(0.5))
                .frame(width: 140, height: 8)
                .offset(y: -5)
        }
    }
}

// MARK: - Sprite Shapes

struct BiplaneSpriteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        // Fuselage
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.45))
        path.addQuadCurve(to: CGPoint(x: w * 0.9, y: h * 0.55), control: CGPoint(x: w, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.55))
        path.closeSubpath()

        // Top wing
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.45))
        path.closeSubpath()

        // Bottom wing
        path.move(to: CGPoint(x: w * 0.25, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.55))
        path.closeSubpath()

        // Tail
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.2))
        path.addLine(to: CGPoint(x: w * 0.14, y: h * 0.45))
        path.closeSubpath()

        return path
    }
}

struct RocketSpriteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        // Pointed nose
        path.move(to: CGPoint(x: w, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: w * 0.8, y: h * 0.2), control: CGPoint(x: w * 0.95, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.5), control: CGPoint(x: w * 0.95, y: h * 0.7))
        path.closeSubpath()

        // Fins
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.25))
        path.closeSubpath()

        path.move(to: CGPoint(x: w * 0.08, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.75))
        path.closeSubpath()

        return path
    }
}

// MARK: - Shared Shapes (kept from original)

struct JetPlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.05, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.35), control: CGPoint(x: 0, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.45), control: CGPoint(x: w * 0.97, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.52), control: CGPoint(x: w * 0.97, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.55))
        path.closeSubpath()

        // Top wing
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.02))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.38))
        path.closeSubpath()

        // Bottom wing
        path.move(to: CGPoint(x: w * 0.32, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.55))
        path.closeSubpath()

        // Tail fin
        path.move(to: CGPoint(x: w * 0.06, y: h * 0.35))
        path.addLine(to: CGPoint(x: w * 0.02, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.14, y: h * 0.35))
        path.closeSubpath()

        return path
    }
}

struct CockpitShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        return path
    }
}

struct ContrailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.midY),
            control: CGPoint(x: rect.midX, y: rect.midY + 3)
        )
        path.addLine(to: CGPoint(x: 0, y: rect.midY + rect.height))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + rect.height * 0.5),
            control: CGPoint(x: rect.midX, y: rect.midY + rect.height - 2)
        )
        path.closeSubpath()
        return path
    }
}

struct TowCable: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY - 4))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.midY - 2),
            control: CGPoint(x: rect.midX, y: rect.maxY)
        )
        return path
    }
}
