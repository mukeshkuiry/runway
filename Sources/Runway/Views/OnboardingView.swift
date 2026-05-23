import SwiftUI

/// First-launch onboarding window asking user to connect Google Calendar
struct OnboardingView: View {
    let onConnected: () -> Void

    @State private var isConnecting = false
    @State private var connectionFailed = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Runway")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Your meetings, cleared for takeoff")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            Spacer().frame(height: 30)

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "calendar.badge.clock", color: .blue, title: "Smart Dashboard", description: "See all upcoming meetings with full details")
                FeatureRow(icon: "airplane", color: .purple, title: "Flyover Alerts", description: "Animated on-screen alerts before meetings")
                FeatureRow(icon: "display.2", color: .teal, title: "Multi-Monitor", description: "Works across all your screens and Spaces")
                FeatureRow(icon: "bolt.fill", color: .orange, title: "Auto-Launch", description: "Starts with your Mac, always ready")
            }
            .padding(.horizontal, 30)

            Spacer().frame(height: 30)

            // Connect button
            VStack(spacing: 12) {
                Button(action: connectGoogle) {
                    HStack(spacing: 10) {
                        if isConnecting {
                            ProgressIndicator()
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isConnecting ? "Connecting..." : "Connect Google Calendar")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.4, green: 0.3, blue: 0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isConnecting)

                if connectionFailed {
                    Text("Connection failed. Please try again.")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }

                Text("We only read your calendar events. Nothing is stored externally.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)

            Spacer().frame(height: 30)
        }
        .frame(width: 420, height: 540)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func connectGoogle() {
        isConnecting = true
        connectionFailed = false

        GoogleAuthManager.shared.startSignIn { success in
            DispatchQueue.main.async {
                isConnecting = false
                if success {
                    onConnected()
                } else {
                    connectionFailed = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Simple spinning progress indicator for SwiftUI
struct ProgressIndicator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.startAnimation(nil)
        return indicator
    }
    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {}
}
