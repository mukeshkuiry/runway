import SwiftUI

/// 5-minute alert: Professional plane glides across center screen towing a meeting banner
struct ReminderAlertView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void

    @State private var positionX: CGFloat = -500
    @State private var engineGlow: Double = 0.6
    @State private var bannerWave: CGFloat = 0

    let animTimer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.startTime)
    }

    var body: some View {
        ZStack {
            Color.clear

            HStack(spacing: 0) {
                // === THE PLANE ===
                ZStack {
                    // Contrail
                    ContrailShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                        .frame(width: 180, height: 8)
                        .offset(x: -120, y: 8)

                    // Plane body
                    JetPlaneShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.82, green: 0.84, blue: 0.88)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 50)

                    // Plane outline
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

                // === TOW CABLE ===
                TowCable()
                    .stroke(
                        Color(red: 0.4, green: 0.4, blue: 0.45),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 50, height: 20)

                // === BANNER ===
                HStack(spacing: 12) {
                    // Meeting icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.25, green: 0.45, blue: 0.95).opacity(0.15))
                            .frame(width: 34, height: 34)
                        Image(systemName: "calendar")
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
                    }

                    Spacer().frame(width: 8)

                    Text(timeText)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(red: 0.6, green: 0.7, blue: 1.0))
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
            .position(x: positionX, y: screenHeight * 0.42)
        }
        .onReceive(animTimer) { _ in
            engineGlow = Double.random(in: 0.5...0.9)
            bannerWave = sin(Date().timeIntervalSinceReferenceDate * 2.5) * 2
        }
        .onAppear {
            let center = screenWidth / 2

            // Phase 1: Fly in to center (3s, ease out)
            withAnimation(.easeOut(duration: 3.0)) {
                positionX = center
            }

            // Phase 2: Hold at center for 6 seconds, then fly out
            DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
                withAnimation(.easeIn(duration: 3.0)) {
                    positionX = screenWidth + 500
                }
            }

            // Phase 3: Dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 12.1) {
                completion()
            }
        }
    }
}

/// Start-time alert: Faster, red-tinted urgent plane flyover
struct UrgentAlertView: View {
    let meeting: MeetingEvent
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let completion: () -> Void

    @State private var positionX: CGFloat = -500
    @State private var engineGlow: Double = 0.8
    @State private var pulseOpacity: Double = 1.0

    let animTimer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meeting.startTime)
    }

    var body: some View {
        ZStack {
            Color.clear

            HStack(spacing: 0) {
                // === THE PLANE (urgent red tint) ===
                ZStack {
                    // Contrail — thicker, more visible
                    ContrailShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0)],
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                        .frame(width: 220, height: 10)
                        .offset(x: -140, y: 8)

                    // Plane body
                    JetPlaneShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.93, blue: 0.93), Color(red: 0.85, green: 0.78, blue: 0.78)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 50)

                    // Red accent stripe
                    Rectangle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 70, height: 3)
                        .offset(x: 0, y: 8)

                    // Plane outline
                    JetPlaneShape()
                        .stroke(Color(red: 0.6, green: 0.4, blue: 0.4), lineWidth: 1.2)
                        .frame(width: 120, height: 50)

                    // Cockpit
                    CockpitShape()
                        .fill(Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.8))
                        .frame(width: 16, height: 10)
                        .offset(x: 48, y: 0)

                    // Engine afterburner
                    Ellipse()
                        .fill(Color.orange.opacity(engineGlow * 0.5))
                        .frame(width: 18, height: 10)
                        .offset(x: -55, y: 12)
                }

                // === TOW CABLE ===
                TowCable()
                    .stroke(
                        Color(red: 0.5, green: 0.35, blue: 0.35),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 40, height: 20)

                // === URGENT BANNER ===
                HStack(spacing: 12) {
                    // Pulsing dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                        .opacity(pulseOpacity)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("STARTING NOW")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(Color.red)
                            .tracking(0.8)

                        Text(meeting.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer().frame(width: 8)

                    if meeting.conferenceURL != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Join")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.15, green: 0.1, blue: 0.1))
                        .shadow(color: .red.opacity(0.2), radius: 16, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                )
            }
            .position(x: positionX, y: screenHeight * 0.42)
        }
        .onReceive(animTimer) { _ in
            engineGlow = Double.random(in: 0.6...1.0)
            pulseOpacity = sin(Date().timeIntervalSinceReferenceDate * 6) > 0 ? 1.0 : 0.3
        }
        .onAppear {
            let center = screenWidth / 2

            // Phase 1: Fly in to center (2.5s, ease out)
            withAnimation(.easeOut(duration: 2.5)) {
                positionX = center
            }

            // Phase 2: Hold for 6 seconds, then fly out
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) {
                withAnimation(.easeIn(duration: 2.5)) {
                    positionX = screenWidth + 500
                }
            }

            // Phase 3: Dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 11.1) {
                completion()
            }
        }
    }
}

// MARK: - Shared Shapes

struct JetPlaneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Fuselage
        path.move(to: CGPoint(x: w * 0.05, y: h * 0.55))
        path.addQuadCurve(to: CGPoint(x: w * 0.05, y: h * 0.35),
                          control: CGPoint(x: 0, y: h * 0.45))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w, y: h * 0.45),
                          control: CGPoint(x: w * 0.97, y: h * 0.38))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.52),
                          control: CGPoint(x: w * 0.97, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.05, y: h * 0.55))
        path.closeSubpath()

        // Top wing (swept back)
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
